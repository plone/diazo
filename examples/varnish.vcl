backend default {
    .host = "127.0.0.1";
    .port = "8000";
}

sub vcl_recv {
    set req.backend = default;
}

sub vcl_fetch {
    if (obj.http.Content-Type == "text/html; charset=utf-8") {
        esi;
    }
}
