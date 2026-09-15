local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local capi = import 'lib/capi-core.libsonnet';

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
    replacements: [
      {
        source: {
          kind: 'Service',
          version: 'v1',
          name: 'controller-manager-metrics-service',
          fieldPath: 'metadata.namespace',
        },
        targets: [
          {
            select: {
              kind: 'Certificate',
              group: 'cert-manager.io',
              version: 'v1',
              name: 'metrics-certs',
            },
            fieldPaths: [
              'spec.dnsNames.0',
              'spec.dnsNames.1',
            ],
            options: {
              delimiter: '.',
              index: 1,
              create: true,
            },
          },
        ],
      },
      {
        source: {
          kind: 'Service',
          version: 'v1',
          name: 'webhook-service',
          fieldPath: '.metadata.namespace',
        },
        targets: [
          {
            select: {
              kind: 'Certificate',
              group: 'cert-manager.io',
              version: 'v1',
              name: 'serving-cert',
            },
            fieldPaths: [
              '.spec.dnsNames.0',
              '.spec.dnsNames.1',
            ],
            options: {
              delimiter: '.',
              index: 1,
              create: true,
            },
          },
        ],
      },
      {
        source: {
          kind: 'Certificate',
          group: 'cert-manager.io',
          version: 'v1',
          name: 'serving-cert',
          fieldPath: '.metadata.namespace',
        },
        targets: [
          {
            select: {
              kind: 'ValidatingWebhookConfiguration',
            },
            fieldPaths: [
              '.metadata.annotations.[cert-manager.io/inject-ca-from]',
            ],
            options: {
              delimiter: '/',
              index: 0,
              create: true,
            },
          },
        ],
      },
      {
        source: {
          kind: 'Certificate',
          group: 'cert-manager.io',
          version: 'v1',
          name: 'serving-cert',
          fieldPath: '.metadata.namespace',
        },
        targets: [
          {
            select: {
              kind: 'MutatingWebhookConfiguration',
            },
            fieldPaths: [
              '.metadata.annotations.[cert-manager.io/inject-ca-from]',
            ],
            options: {
              delimiter: '/',
              index: 0,
              create: true,
            },
          },
        ],
      },
    ],
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
} + capi.kustomize_crd_clusterctl_label_patch
