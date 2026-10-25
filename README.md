# Plack-Middleware-Zitadel

Plack middleware to validate `Authorization: Bearer <token>` with ZITADEL OIDC,
then forward verified claims to your app via PSGI env.

## Installation

```bash
cpanm Plack::Middleware::Zitadel
```

## Usage

```perl
use Plack::Builder;

my $app = sub {
    my ($env) = @_;
    my $claims = $env->{'zitadel.claims'} || {};
    return [200, ['Content-Type' => 'application/json'], ['ok']];
};

my $wrapped = builder {
    enable 'Plack::Middleware::Zitadel',
        issuer          => 'https://zitadel.example.com',
        audience        => 'my-api',
        required_scopes => ['openid', 'profile'];
    $app;
};
```

## Transparent Proxy Example

A ready-to-run proxy app is included in `examples/proxy.psgi`.

It verifies the Bearer token, then forwards the request to `UPSTREAM_BASE`.

Run locally:

```bash
ZITADEL_ISSUER='https://zitadel.example.com' \
UPSTREAM_BASE='http://127.0.0.1:8080' \
plackup -Ilib examples/proxy.psgi -p 5000
```

## Docker

Build and run the proxy container:

```bash
docker build -f examples/Dockerfile -t zitadel-auth-proxy:dev .

docker run --rm -p 5000:5000 \
  -e ZITADEL_ISSUER='https://zitadel.example.com' \
  -e UPSTREAM_BASE='http://host.docker.internal:8080' \
  zitadel-auth-proxy:dev
```

## Kubernetes (Gateway API)

K8s manifests are provided under `examples/k8s/`:

- `configmap.yaml`
- `deployment.yaml`
- `service.yaml`
- `httproute.yaml`

All hostnames, the image and the gateway in the manifests are placeholders.
In this order:

1. Set your values in `examples/k8s/configmap.yaml`: `ZITADEL_ISSUER`
   (and optionally `ZITADEL_AUDIENCE`, `ZITADEL_REQUIRED_SCOPES`) and
   `UPSTREAM_BASE`.
2. Build and push the image (see Docker above), e.g.
   `docker build -f examples/Dockerfile -t registry.example.com/zitadel-auth-proxy:1 .`
3. Adjust the manifests: the `image` in `examples/k8s/deployment.yaml`, and the
   gateway (`parentRefs`) and `hostnames` in `examples/k8s/httproute.yaml`.
4. Apply:

   ```bash
   KUBECONFIG_PATH=~/.kube/config examples/deploy-k8s-proxy.sh
   ```

   `KUBECONFIG_PATH` defaults to `~/.kube/config`, `NAMESPACE` to `zitadel`.
   The script prints the namespace and the gateway name the route is attached to.
