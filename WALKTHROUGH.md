# Step-by-step Walkthough of URL Shortener App

This page is a step-by-step walkthough of my development process for this web app. These steps include all the info you'd need to build a similar app yourself, including the environment setup, source code, testing, and potential room for improvement.

# Table of Contents

- [Elixir Setup and Phoenix Boilerplate](#elixir-setup-and-phoenix-boilerplate)
- [Data Model and CRUD Functionality](#data-model-and-crud-functionality)
- [Redirect to External URLs](#redirect-to-external-urls)
- [Generate Random Slugs](#generate-random-slugs)
- [Stats Page and CSV Download](#stats-page-and-csv-download)

&nbsp;
# Elixir Setup and Phoenix Boilerplate

To set up my Elixir environment, I used the [official installation instructions](https://elixir-lang.org/install.html)
and installed the current latest version of Elixir (1.14.2). I used [asdf](https://github.com/asdf-vm/asdf)
to manage the runtime version for my environment, so this Elixir version is configured in the
`.tool-versions` file in this repository. I installed Phoenix using the [official installation instructions](https://hexdocs.pm/phoenix/installation.html)
as well, along with Hex (package manager) and Ecto (database toolkit).

Phoenix provides [generators](https://hexdocs.pm/phoenix/up_and_running.html) to bootstrap
applications by generating boilerplate code for a simple web app. I used this CLI command to generate
a basic web app, with only the minimal set of features I needed:

```
mix phx.new url_shortener --no-dashboard --no-live --no-gettext --no-mailer --binary-id
```

For local development, I used [Postgres.app](https://postgresapp.com/) to run a locally hosted
PostgreSQL database. After generating the boilerplate code for my app, I added the credentials
for my local Postgres.app server to the `dev.ex` config file and used `$ mix ecto.create` to create
a new database.

&nbsp;
# Data Model and CRUD Functionality

This web app needs a database to store the URL slugs (the aliases users will use
to create shortened URLs). Since every component of the app relies on the database,
I started development by creating this data model. For basic functionality, my
data model uses a single table with three columns:

- **original_url:** The full external URL that users want to visit, like "https://www.google.com/"
- **alias:** The short suffix that users will use as a shortcut to visit the original url
- **count_visits:** The number of times user has visited the shortened URL

To turn this schema into code, I used another Phoenix generator: `mix phx.gen.context`.
This generator takes a simple table schema as command-line parameters and generates
source code for a full CRUD app, with a complete model, view and controller.
I used this command to create a new resource for my table, **slugs**:

```
mix phx.gen.html Slugs Slug slugs original_url:string alias:string count_visits:integer
```

&nbsp;
## Schema and Changeset

For this app, the auto-generated schema meets most of my needs. I only made one small tweak:
give `count_visits` a default value of zero so that I don't need to set it manually.

#### **`lib/url_shortener/slugs/slug.ex`**
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "slugs" do
    field :count_visits, :integer, default: 0
    field :original_url, :string
    field :slug, :string

    timestamps()
  end
```

Notice that this schema also has an `id` column (a UUID) and timestamps for `updated_at`
and `inserted_at`. We won't use them at all, but they can be useful for debugging or
extending the functionality.

Along with the schema, the generated code included a simple changeset. I added extra rules to this changeset to validate the two provided fields:

- **original_url:** Needs to be a valid URL. I'll validate this with regular expression.
- **alias**: Can't be an empty string, shouldn't be excessively long (kinda defeats the point of the shortener 🤨), and most importantly, needs to be unique so that each alias maps to a URL.

Here's my changeset with these validations:

#### **`lib/url_shortener/slugs/slug.ex`**
```elixir
  def changeset(slug, attrs) do
    slug
    |> cast(attrs, [:original_url, :alias])
    |> validate_required([:original_url, :alias])
    # Only allow valid URL that start with http(s)://{domain}/
    # Use \S to avoid whitespace in or after URL
    |> validate_format(:original_url, ~r/^https?:\/\/\S*\/\S*$/)
    # Slugs must be valid URL suffixes and shouldn't be excessively long.
    # The `stats` route can't be reserved since it's already used.
    |> validate_exclusion(:alias, "stats")
    |> validate_length(:alias, min: 1, max: 72)
    |> validate_format(:alias, ~r/[A-Za-z0-9_-]+/)
    # Don't allow multiple slugs with different emails
    |> unique_constraint(:alias)
  end
```

*(A better URL shortener would have a much more refined regex here. I'm focused on writing a web backend, not on the intricacies of URL names, so I'll keep this basic).*

I discovered a little quirk about that `unique_constraint`: it requires adding
an index to the database via a migration. I decided to modify the existing migration file and rebuild the database to keep things simple:

#### **`priv/repo/migrations/20230108230654_create_slugs_table.exs`**
```diff
defmodule UrlShortener.Repo.Migrations.CreateSlugsTable do
  use Ecto.Migration

  def change do
    create table(:slugs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :original_url, :string
      add :slug, :string
      add :count_visits, :integer, default: 0

      timestamps()
    end

+   create unique_index(:slugs, [:slug])
  end
end
```

&nbsp;
## Trimming the Context and Controller Modules

Unlike the schema module that I left mostly the same, most of the generated context module needed a major overhaul. My app techincally isn't a CRUD app; there's no mechanism for deleting aliases, and users can't update existing aliases either. Without an authorization mechanism, update and delete features would let users modify or remove other users' aliases. An evil hacker could use the list of slugs to route users to fake websites for phishing scams, identity theft, or all sorts of tomfoolery. Or, perhaps more likely, a clueless user could accidentally delete everyone else's slugs. Either way, we shouldn't include update and delete features without user authentification.

To start off, I removed the `upload_slug` and `delete_slug` functions and left these three functions, which we'll use later on:

#### **`lib/url_shortener/slugs.ex`**
```elixir
  def list_slugs do
    Repo.all(Slug)
  end

  def change_slug(%Slug{} = slug, attrs \\ %{}) do
    Slug.changeset(slug, attrs)
  end

  def create_slug(attrs) do
    %Slug{}
    |> Slug.changeset(attrs)
    |> Repo.insert()
  end
```

Similar with the controller, I held onto the functions for creating and listing slugs and discarded the rest. I renamed `index` to `stats` since that list page won't be the landing point for the app, but otherwise I left these the same:

#### **`lib/url_shortener_web/controllers/slug_controller.ex`**
```elixir
  def new(conn, _params) do
    changeset = Slugs.change_slug(%Slug{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"slug" => slug_params}) do
    case Slugs.create_slug(slug_params) do
      {:ok, slug} ->
        conn
        |> put_flash(:info, "Slug created successfully.")
        |> render("show.html", slug: slug)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def stats(conn, _params) do
    slugs = Slugs.list_slugs()
    render(conn, "stats.html", slugs: slugs)
  end
```

These three functions correspond to three routes. The first, `new`, is the landing page for the app and displays a form for creating a new short URL. The second, `create`, is for submitting a new slug and rendering a page to show either the new slug or the error. Third, that `stats` function is for listing all slug stats (we'll cover this more later).

I updated the router module to assign these functions to their proper routes:

#### **`lib/url_shortener_web/router.ex`**
```elixir
  scope "/", UrlShortenerWeb do
    pipe_through :browser

    get "/", SlugController, :new do
      post "/", SlugController, :create
    end

    get "/stats", SlugController, :index

  end
```

Finally, I updated the HTML templates referenced in each of the controller functions above: `new.html`, `show.html`, and `stats.html`. I'll leave that code out of this writeup since it's long, mostly cosmetic and rather tedious.

With these changes complete, I finally had a working app that I could run in my browser. This means I could get started on the most exiting part of development: writing tests!

&nbsp;
## Tests

The Phoenix generator gave me simple modules for unit tests (for the model and context modules) and integration tests (for the controller and view). In parallel with the trimming and tweaks I made to those modules, I trimmed down the tests and added a few of my own.

The unit tests came with tests for `list_slugs`, `change_slug` and `create_slug`. The first two functions and their tests are fairly simple, so I made no changes there. For `create_tests`, I added five tests to test my changeset validations:

#### **`test/url_shortener/slugs_test.exs`**
```elixir
  describe "create_slug" do
    @valid_attrs %{"original_url" => "https://en.wikipedia.org/", "alias" =>  "wiki"}
    @invalid_attrs %{"original_url" => nil, "alias" =>  nil}

    test "create_slug/1 with valid data creates a slug" do
      assert {:ok, %Slug{} = slug} = Slugs.create_slug(@valid_attrs)
      assert slug.count_visits == 0
      assert slug.original_url == "https://en.wikipedia.org/"
      assert slug.alias == "wiki"
    end

    test "create_slug/1 with invalid data doesn't insert new record" do
      assert {:error, %Ecto.Changeset{}} = Slugs.create_slug(@invalid_attrs)
      assert Slugs.list_slugs() == []
    end

    test "create_slug/1 enforces unique slug names" do
      assert {:ok, first_slug} = Slugs.create_slug(@valid_attrs)
      assert {:error, changeset} = Slugs.create_slug(@valid_attrs)
      assert %{alias: ["has already been taken"]} = errors_on(changeset)
      assert Slugs.list_slugs() == [first_slug]
    end

    test "does not accept invalid urls" do
      for invalid_url <- [
        "wikipedia",
        "en.wikipedia.org",
        "https://en.wikipedia.org",
        "https://en.wikipedia.org/   "
      ] do
      attrs = Map.put(@valid_attrs, "original_url", invalid_url)
      assert {:error, changeset} = Slugs.create_slug(attrs)
      assert %{original_url: ["has invalid format"]} = errors_on(changeset)
      end
      assert Slugs.list_slugs() == []
    end

    test "does not accept slugs over 72 characters long" do
      attrs = Map.put(@valid_attrs, "alias", String.duplicate("w", 73))
      {:error, changeset} = Slugs.create_slug(attrs)

      assert %{alias: ["should be at most 72 character(s)"]} = errors_on(changeset)
      assert Slugs.list_slugs() == []
    end
  end
```

The first two tests are straightforward; insert a normal URL/alias pair or an empty pair and check for the `:ok` or `:error` response. The third test checks the uniqueness constraint by inserting the same slug twice and checking for the error on the second try, along with making sure the database contains one record. The fourth and fifth tests test the validation for incorrect URLs and aliases.

*These tests could be much more thorough, especially for testing the regular expression. We also don't have tests for the columns we don't use (the id and timestamp columns). However, these unit tests get 100% code coverage against `slug.ex` and `slugs.ex` - not that code coverage is the best metric, but enough to give some peace of mind and speed up testing as we add on to these.*

For the controller, I added three simple tests:

#### **`test/url_shortener_web/controllers/slug_controller_test.exs`**
```elixir
  @create_attrs %{original_url: "https://en.wikipedia.org/", slug: "wiki"}
  @invalid_attrs %{original_url: nil, slug: nil}

  test "renders form", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Create a short URL"
    assert html_response(conn, 200) =~ "Create URL"
  end

  test "displays new slug when slug is valid", %{conn: conn} do
    conn = post(conn, "/", slug: @create_attrs)

    assert html_response(conn, 200) =~ "Created new short URL!"
    assert html_response(conn, 200) =~ @create_attrs.original_url
    assert html_response(conn, 200) =~ @create_attrs.alias

    conn = get(conn, "/stats")
    assert html_response(conn, 200) =~ @create_attrs.original_url
    @create_attrs.alias

  end

  test "renders errors when data is invalid", %{conn: conn} do
    conn = post(conn, Routes.slug_path(conn, :create), slug: @invalid_attrs)
    assert html_response(conn, 200) =~ "Create a short URL"
    assert html_response(conn, 200) =~ "Oops, something went wrong!"
  end
```

These tests cover the three routes we've created so far and validate the output by searching for text within the rendered HTML. Again, these tests are simple so far, but they're loosely coupled to the template design and cover all our routes.


&nbsp;
# Redirect to External URLs

Now that we've endured the tedious task of laying out this basic groundwork, we can finally look at some more interesting features. This app's most important feature is redirecting any user-provided URL slug to an external website, so we'll move on to that.

## Data Model Updates

Before adding a new route, I added two new functions to the context:

#### **`lib/url_shortener/slugs.ex`**
```elixir
  def get_url_from_slug(lookup_alias) do
    query = from slug in "slugs",
            where: slug.alias == type(^lookup_alias, :string),
            select: slug.original_url
    # Since update_all returns the number of updated rows and the selected
    # results, use the return to determine whether the URL was found.
    case Repo.update_all(query, [inc: [count_visits: 1]]) do
      {0, _} -> {:error,  "Alias not found in database"}
      {1, [original_url]} -> {:ok,  original_url}
    end
  end
```

This function uses a SQL-style query (thank you Ecto's query DSL) to fetch the URL for an alias. We'll need this to find the URL our users are trying to visit. It also takes advantage of Postgres' ability to update and select in the same query, incrementing `count_visits` whenever a user visits the URL. The index we created for the `alias` column earlier should make this query fast and ensure there's only one matching URL.

#### **`lib/url_shortener_web/controllers/slug_controller.ex`**
```elixir
  def redirect_to_url(conn, %{"lookup_alias" => [lookup_alias]}) do
    case Slugs.get_url_from_slug(lookup_alias) do
      {:ok, original_url} ->
        conn
        |> put_flash(:info, "Redirecting to original URL")
        |> redirect(external: original_url)
      # If user enters a slug that isn't in the database,
      # redirect to a custom 404 error page.
      {:error, _reason} ->
        conn
        |> put_status(404)
        |> render("error.html", lookup_alias: lookup_alias)
    end
  end
```

Our new controller function uses `get_url_from_slug` to look up the alias provided
by the user, get the corresponding URL, and redirect the user to that URL. If the
slug doesn't exist, the user will receive a 404 response with our custom error page.
This will override Phoenix's normal behavior for handling 404 errors in the error view
module, which I left as-is (since the workaround makes it clean and simple to display
the alias in the error page).

To handle the routing, I added a wildcard route that intercepts all undefined routes in our router:

#### **`lib/url_shortener_web/router.ex`**
```diff
    get "/", SlugController, :new do
      post "/", SlugController, :create
    end

    get "/stats", SlugController, :index

+   get "/*lookup_alias", SlugController, :redirect_to_url
```

With this new route, we now have a working URL shortener! Even though it's a barebones solution (a minimum viable product), it accomplishes the task it was created for. All future changes will be enhancements to our working product.


&nbsp;
## Tests
For the two new functions above, I added a couple unit and integration tests:

#### **`test/url_shortener/slugs_test.exs`**
```elixir
  describe "routing_multiple_urls" do
    @url1 "https://en.wikipedia.org/"
    @url2 "https://xkcd.com/1700"
    @valid_attrs1 %{"original_url" => @url1, "alias" =>  "wiki"}
    @valid_attrs2 %{"original_url" => @url2, "alias" =>  "xkcd"}

    setup do
      Slugs.create_slug(@valid_attrs1)
      Slugs.create_slug(@valid_attrs2)
      :ok
    end

    test "get_url_from_slug/1 fetches correct urls" do
      assert {:ok, @url1} == Slugs.get_url_from_slug("wiki")
      assert {:ok, @url2} == Slugs.get_url_from_slug("xkcd")
    end

    test "get_url_from_slug/1 error handling" do
      assert {:error,  "Alias not found in database"} == Slugs.get_url_from_slug("fake")
    end

    test "increment_visit_count/1 increments counts correctly" do
      assert {:ok, @url1} == Slugs.get_url_from_slug("wiki")
      assert {:ok, @url1} == Slugs.get_url_from_slug("wiki")
      assert {:ok, @url2} == Slugs.get_url_from_slug("xkcd")
      assert {:ok, @url2} == Slugs.get_url_from_slug("xkcd")
      assert {:ok, @url2} == Slugs.get_url_from_slug("xkcd")

      assert [first_slug, second_slug] = Slugs.list_slugs()
      assert first_slug.count_visits == 2
      assert second_slug.count_visits == 3
    end
  end
```
These unit tests are straightforward - check the happy path and error path of our function, and make sure `count_visits` is getting incremented properly.

#### **`test/url_shortener_web/controllers/slug_controller_test.exs`**
```elixir
  describe "redirection" do
    setup [:create_slug]

    test "redirects to external url", %{conn: conn} do
      conn = get(conn, "/#{@create_attrs.alias}")
      assert redirected_to(conn) == @create_attrs.original_url
    end

    test "redirects to 404 for nonexistant slug", %{conn: conn} do
      conn = get(conn, "/nonexistant")
      assert html_response(conn, 404) =~
        "Error 404: URL shortcut \"nonexistant\" not found"
    end

    test "stats page updated after visiting external url", %{conn: conn} do
      for _ <- 1..7 do
        _conn = get(conn, "/#{@create_attrs.alias}")
      end

      conn = get(conn, "/stats")
      assert html_response(conn, 200) =~
        Regex.compile!("#{@create_attrs.alias}[\<\\/td\\>\\s]*7")
    end
  end
```
These integration tests use some of the Phoenix helper functions for testing. The first uses `redirected_to` to confirm that we get redirected to the correct URL, and the second uses `html_response` to check for the 404 HTTP status. The third test checks that the `/stats` page has the correct visit count after visiting the URL seven times. While we don't *need* the regex there, it gives us an easy way to test that the URL and the number 7 appear in the same table row.


&nbsp;
# Generate Random Slugs
A useful feature for our URL shortener is generating slugs for our users. So far, our app requires users to provide their own slugs, but this isn't convenient for many use cases. Especially as the number of users increases, we'd like a simple solution for users to create short, simple URLs on the fly, without worrying about collisions or URL limitations.

Keeping thing simple, I wrote a function to generate random mixed-case alphanumeric strings with the built-in Elixir `Enum.take_random` functions. The default length is (26 + 26 + 10)^5 = 916 million possible aliases, with an optional parameter to allow longer slugs:

#### **`lib/url_shortener/helper.ex`**
```elixir
  def create_random_slug(slug_length \\ 5) do
    # To create an N-length random string, randomly select N alphanumeric
    # characters into a list, then convert that charlist to a string.
    Enum.concat([?0..?9, ?a..?z, ?A..?Z])
    |> Enum.take_random(slug_length)
    |> to_string
  end
```

*Sidenote: originally I put this function in the slugs.ex module. However, I had to move it to its own module, helpers.ex, to mock the random behavior for unit testing (see details below).*

Next up, we need a new function in the context module to create and insert a new alias. This function needs collision detection: if our random alias already exists in the database, we'll need to create a new one and try again, possibly multiple times. Our data model already has a unique constraint for the `alias` column, so we can use our changeset to detect if an alias is taken when we try to insert it. That way, we can use the same insertion code for both random aliases and user-provided aliases.

Here are the functions to handle this logic:

#### **`lib/url_shortener/slugs.ex`**
```elixir
  defp insert_slug(attrs) do
    %Slug{}
    |> Slug.changeset(attrs)
    |> Repo.insert()
  end

  def slug_taken?(%Ecto.Changeset{} = changeset) do
    case changeset.errors[:alias] do
      {_, [constraint: :unique, constraint_name: _]} -> true
      _ -> false
    end
  end

  defp generate_and_insert_slug(attrs, alias_length \\ 5) do
    random_slug = Helpers.create_random_slug(alias_length)
    case insert_slug(Map.put(attrs, "alias", random_slug)) do
      {:ok, insert_result} -> {:ok, insert_result}
      {:error, changeset} ->
        # If the randomly generated slug was already taken,
        # try again with a different random slug.
        if slug_taken?(changeset) do
          generate_and_insert_slug(attrs, alias_length + 1)
        # If any other error occurs, send the error back to the user
        # but don't send back the slug (leave the slug blank).
        else
          stripped_changeset = changeset
          |> Map.put(:changes, %{changeset.changes | alias: ""})
          |> Map.put(:data, %{changeset.data | alias: ""})
          {:error, stripped_changeset}
        end
    end
  end
```

The first two helper functions just insert the new slug and check if a changeset says a slug has already been taken. The third function uses these and `create_random_slug` to generate and insert a random slug. If the slug is taken, we'll use tail recursion to try again. When the database is mostly empty, this recursive loop will rarely get called; however, if we had hundreds of millions of aliases, we'd want to avoid long or infinite loops before finding an unused alias. We avoid that by increasing the alias length whenever we find a collision, to six, seven or more characters when needed. By increasing with every recursive call, we'll make it extremely rare to loop more than 2-3 times, even with trillions of aliases.

When any other validation error occurs, we still want to send the results back to the user, but not the random alias. We handle that in the `else` block above.

Finally, I rewrote the `create_slug` function and this new feature was complete:

#### **`lib/url_shortener/slugs.ex`**
```elixir
  def create_slug(attrs) do
    # If user does not provide a alias, then generate a random slug
    if attrs["alias"] == "" do
      generate_and_insert_slug(attrs)
    # If user provides a slug, do a simple insert and return the changeset
    else
      insert_slug(attrs)
    end
  end
```


&nbsp;
## Testing

Random behavior can be tricky to test. Theoretically, unit tests are supposed to be predictable enough that we can compare our function's outputs with expected values, since we don't want to miss a bug caused by rare random behavior. Our new functions have two behaviors we want to test:

1. `create_random_slug` should always create a useable URL slug.
2. Our collision detection should succeed when the new random slug is already taken.

I'm not too worried about that first behavior, since `create_random_slug` is short and simple. I created a unit test that seeds the random number generator for repeatability, and quickly (in 0.01 seconds) tests 1000 random slugs:

#### **`test/url_shortener/helpers_test.exs`**
```elixir
  test "create_random_slug/0" do
    :rand.seed(:exsss, {1000, 1000, 1000})
    for _ <- 1..1000 do
      assert Helpers.create_random_slug()
      |> String.match?(~r/^[[:alnum:]]{5}$/)
    end
  end
```

Testing the collision detection is more challenging. With nearly a billion random slugs, our unit test would take forever to run if we relied on random behavior, even with seeds (especially each insertion hits the Postgres database). Even if I found a seed that created two identical slugs in the first two function calls, that test would break if I modified `create_random_slug` in any way. The only to write useful, scalable tests for this feature is by removing the random behavior completely via dependency mocking.

*Note: Apparently, mocking isn't popular in the Elixir world. I guess that concept doesn't totally align with the functional programming philosophy of pure functions and zero side effects. However, I'm an FP heathen from the lawless Python world where programming has no rules, so I'll stick with mocking instead of a more complex "pure" approach.*

I used a library called [Mimic](https://github.com/edgurgel/mimic) to create a mock of the Helpers module. Mimic builds on the Mox library created by Elixir's creator José Valim, but requires much less boilerplate code *and* supports async tests. Here's how I mock out the Helpers module:

#### **`test/test_helper.exs`**
```elixir
Mimic.copy(UrlShortener.Helpers)
```

And here are the unit tests for random slug creation, collision detection and error handling:

#### **`test/url_shortener/slugs_test.exs`**
```elixir
  describe "random_slug_generation" do
    @valid_attrs %{"original_url" => "https://en.wikipedia.org/", "alias" =>  ""}

    setup do
      stub UrlShortener.Helpers.create_random_slug(), do: "random"
      :ok
    end

    test "create_slug/1 creates random slug if none provided" do
      assert {:ok, %Slug{} = slug} = Slugs.create_slug(@valid_attrs)
      assert slug.original_url == "https://en.wikipedia.org/"
      assert slug.alias == "random"
    end

    test "create_slug/1 avoid random slug collisions" do
      expect UrlShortener.Helpers.create_random_slug(), do: "first"
      expect UrlShortener.Helpers.create_random_slug(), do: "first"

      assert {:ok, %Slug{} = slug1} = Slugs.create_slug(@valid_attrs)
      assert {:ok, %Slug{} = slug2} = Slugs.create_slug(@valid_attrs)
      assert slug1.alias == "first"
      assert slug2.alias == "random"
    end

    test "create_slug/1 invalid URL and empty slug" do
      attrs = %{"original_url" => "en.wikipedia.org", "alias" =>  ""}
      assert {:error, changeset} = Slugs.create_slug(attrs)
      assert %{original_url: ["has invalid format"]} = errors_on(changeset)
      assert changeset.data.alias == ""
    end
  end
```

These tests use the `stub` and `expect` functions to mock `create_random_slug` with just a few lines of code. `stub` sets the default behavior of the mock function and `expect` lets us set specific return values for different times for function is called. For collision detection, it'll try to insert the "first" alias twice, making our `generate_and_insert_slug` recursively try again and insert the "random" alias.


&nbsp;
# Stats Page and CSV Download

Finally, we have one more feature to add: the CSV download button. We already have a stats page from the Phoenix generator, which displays our data pretty well. We'll add a button to this page with a function to download the data, then we'll be finished with this URL shortener.

To create the CSV files, I used the [CSV library](https://github.com/beatrichartz/csv). This function in the context module uses that library to convert the database data (only the three main columns, not including ID and timestamps) into a CSV string:

#### **`lib/url_shortener/slugs.ex`**
```elixir
  def get_csv_data do
    # Query all records from the slugs database table
    # (A more-refined solution would include pagination and some kind of
    # user-based filtering, instead of dumping the entire database.)
    Slug
    |> order_by(:inserted_at)
    |> Repo.all
    # Convert Ecto schema to a CSV string, with human-readable column names
    |> CSV.encode(headers: [
      original_url: "Original URL",
      alias: "Alias",
      count_visits: "Number of Visits"
    ])
    |> Enum.to_list
    |> to_string
  end
```

A more refined solution would have settings for pagination and filtering data, especially if the app had user authentification.

In the controller, I added a function to get the CSV string from `get_csv_data` and send it as an HTTP response. I added this function to our router as a POST request for `/stats`.

#### **`lib/url_shortener_web/controllers/slug_controller.ex`**
```elixir
  def download_csv(conn, _params) do
    csv_data = Slugs.get_csv_data()

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content_disposition",
      "attachment; filename=\"url_shortener_stats.csv\"")
    |> send_resp(200, csv_data)
  end
```

#### **`lib/url_shortener_web/router.ex`**
```diff
    get "/", SlugController, :new do
      # Only use this endpoint for creating new slugs
      post "/", SlugController, :create
    end

    # Use this endpoint to list all urls and slugs
+   get "/stats", SlugController, :stats do
+     post "/stats", SlugController, :download_csv
+   end

    get "/*lookup_alias", SlugController, :redirect_to_url
```

Finally, I added the button to the `stats.html.heex` template using this new route. This wraps up the code for this new feature.

#### **`lib/url_shortener_web/templates/slug/stats.html.heex`**
```html
<%= button to: Routes.slug_path(@conn, :download_csv) do %>
  Download as CSV
<% end %>
```


&nbsp;
## Testing

Since I updated the context and the controller, I'll add both a unit test and an integration test. This unit test below tests `get_csv_data` after retrieving two URLs several times each, so that it can verify the `count_visits` number. The test creates a full CSV string to compare with the function output, using the `Enum.join` functions below. Comparing the entire file to an exact copy might seem like overkill, but given how finicky CSV files can be, I'd rather be extra precise.

#### **`test/url_shortener/slugs_test.exs`**
```elixir
  test "get_csv_data/0" do
    for _ <- 1..5 do Slugs.get_url_from_slug("wiki") end
    for _ <- 1..7 do Slugs.get_url_from_slug("xkcd") end

    assert Slugs.get_csv_data() == Enum.join([
      Enum.join(["Original URL", "Alias", "Number of Visits"], ","),
      Enum.join([@url1, "wiki", "5"], ","),
      Enum.join([@url2, "xkcd", "7"], ","),
      ""
    ], "\r\n")
  end
```

This integration test isn't as specific as the unit test. This test checks the new route we created, checks that the response is a CSV file, and does a rough check that the response contains comma-separated data.

#### **`test/url_shortener_web/controllers/slug_controller_test.exs`**
```elixir
  test "download csv",  %{conn: conn} do
    conn = post(conn, "/stats")
    assert response_content_type(conn, :csv)
    assert response(conn, 200) =~ Enum.join(
      [@create_attrs.original_url, @create_attrs.alias, "0"], ",")
  end
```

*Note: Both of these tests use the same setup as previous tests shown, not pictured in these snippets.*

This wraps up all of our unit and integration tests! Once again, I used the `mix test --cover` CLI command to run all tests and check for code coverage, which is 100% for all the files mentioned above (I excluded other modules in `mix.exs`). One of the strengths of a functional language like Elixir is how easy pure functions are to test and reason about, so for a small greenfield project like this, high test coverage is a reasonable expectation.

Phoenix aficionados might have noticed something missing in this walkthrough: views. I didn't see much need for a view module, other than the boilerplate Phoenix generated to link my HTML templates to the controller. If I added a fancier statistics table or custom error pages (aside from my rough 404 page), Phoenix views could be very handy, and they would merit view tests as well.

#### **`Code Coverage`**
```
url_shortener % mix test --cover
Cover compiling modules ...
..........................
Finished in 0.5 seconds (0.3s async, 0.2s sync)
26 tests, 0 failures

Randomized with seed 194933

Generating cover results ...

Percentage | Module
-----------|--------------------------
    50.00% | UrlShortenerWeb.LayoutView
    50.00% | UrlShortenerWeb.SlugView
    66.67% | UrlShortenerWeb.ErrorView
   100.00% | UrlShortener
   100.00% | UrlShortener.DataCase
   100.00% | UrlShortener.Helpers
   100.00% | UrlShortener.Slugs
   100.00% | UrlShortener.Slugs.Slug
   100.00% | UrlShortener.SlugsFixtures
   100.00% | UrlShortenerWeb.ConnCase
   100.00% | UrlShortenerWeb.Endpoint
   100.00% | UrlShortenerWeb.ErrorHelpers
   100.00% | UrlShortenerWeb.Router
   100.00% | UrlShortenerWeb.Router.Helpers
   100.00% | UrlShortenerWeb.SlugController
-----------|--------------------------
    95.95% | Total
```

