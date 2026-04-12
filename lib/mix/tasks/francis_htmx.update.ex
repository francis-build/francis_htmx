defmodule Mix.Tasks.FrancisHtmx.Update do
  @moduledoc """
  Downloads a specific version of htmx.js and saves it to `priv/static/htmx.min.js`.

  This allows updating the bundled htmx version without relying on a CDN at runtime.

  ## Usage

      mix francis_htmx.update          # downloads the latest v2 release
      mix francis_htmx.update 2.0.4    # downloads a specific version

  The downloaded file is saved to the package's `priv/static/htmx.min.js` and will be
  inlined into the HTML output at compile time. After updating, recompile your project
  to pick up the new version.
  """
  @shortdoc "Downloads a specific version of htmx.js"

  use Mix.Task

  @github_raw "https://raw.githubusercontent.com/bigskysoftware/htmx"
  @github_api "https://api.github.com/repos/bigskysoftware/htmx/releases/latest"

  @impl Mix.Task
  def run(args) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    version = List.first(args) || latest_version()
    url = ~c"#{@github_raw}/v#{version}/dist/htmx.min.js"
    dest = Path.join(:code.priv_dir(:francis_htmx), "static/htmx.min.js")

    Mix.shell().info("Downloading htmx v#{version} from GitHub...")

    case :httpc.request(:get, {url, []}, [ssl: ssl_opts()], []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        File.mkdir_p!(Path.dirname(dest))
        File.write!(dest, body)
        Mix.shell().info("Saved htmx v#{version} to #{dest} (#{IO.iodata_length(body)} bytes)")

      {:ok, {{_, status, _}, _headers, _body}} ->
        Mix.raise("Failed to download htmx v#{version}: HTTP #{status}")

      {:error, reason} ->
        Mix.raise("Failed to download htmx v#{version}: #{inspect(reason)}")
    end
  end

  defp latest_version do
    url = ~c"#{@github_api}"
    headers = [{~c"accept", ~c"application/vnd.github.v3+json"}]

    case :httpc.request(:get, {url, headers}, [ssl: ssl_opts()], body_format: :binary) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        case Jason.decode(body) do
          {:ok, %{"tag_name" => "v" <> version}} -> version
          _ -> raise_version_error()
        end

      _ ->
        raise_version_error()
    end
  end

  defp ssl_opts do
    [
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get(),
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]
  end

  defp raise_version_error do
    Mix.raise(
      "Could not determine latest htmx version. " <>
        "Please specify a version: mix francis_htmx.update 2.0.4"
    )
  end
end
