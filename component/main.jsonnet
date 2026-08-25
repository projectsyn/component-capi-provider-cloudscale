local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.capi_provider_cloudscale;

assert std.member(inv.applications, 'capi-core') : 'Component capi-provider-cloudscale requires component capi-core';
assert std.length(params.variables.CLOUDSCALE_API_TOKEN) > 0 : 'capi-provider-cloudscale:variables:CLOUDSCALE_API_TOKEN must be set';

local manifest_path = 'config/default';

com.Kustomization(
  'https://github.com/cloudscale-ch/cluster-api-provider-cloudscale/' + manifest_path,
  params.images['capi-provider-cloudscale'].tag,
  {
    'quay.io/cloudscalech/capcs-staging': {
      local image = params.images['capi-provider-cloudscale'],
      newTag: image.tag,
      newName: '%(registry)s/%(image)s' % image,
    },
  },
  {
    namespace: params.namespace,
    labels+: [
      {
        pairs: {
          'app.kubernetes.io/managed-by': 'commodore',
        },
      },
    ],
    patchesStrategicMerge: [ 'rm-namespace.yaml' ],
  },
) {
  'rm-namespace': [
    {
      '$patch': 'delete',
      apiVersion: 'v1',
      kind: 'Namespace',
      metadata: {
        name: 'capcs-system',
      },
    },
  ],
}
