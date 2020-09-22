defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: [ "application/json", "application/vnd.api+json" ],
    html: [ "text/html", "application/xhtml+html" ],
    sparql: [ "application/sparql-results+json" ],
    any: [ "*/*" ]
  ]

  define_layers [ :static, :sparql, :api, :frontend_fallback, :not_found ]

  # Static content
  match "/assets/*path", %{ layer: :static } do
    forward conn, path, "http://frontend/assets/"
  end

  match "/index.html", %{ layer: :static } do
    forward conn, [], "http://frontend/index.html"
  end

  # Frontend specific
  match "/sparql", %{ layer: :sparql, accept: %{ html: true } } do
    forward conn, [], "http://frontend/sparql"
  end

  match "/sparql", %{ layer: :sparql, accept: %{ sparql: true } } do
    forward conn, [], "http://database:8890/sparql"
  end

  # API services
  match "/resource-labels/*path", %{ layer: :api, accept: %{ json: true } } do
    forward conn, path, "http://resource-labels/"
  end

  match "/uri-info/*path", %{ layer: :api, accept: %{ json: true } } do
    forward conn, path, "http://uri-info/"
  end

  # Frontend pages
  match "/*path", %{ layer: :frontend_fallback, accept: %{ html: true } } do
    # We forward path for fastboot
    forward conn, path, "http://frontend/"
  end

  # Not found
  match "/*_path", %{ layer: :not_found } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end
end
