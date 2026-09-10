/**
 * \file Library with public methods provided by component capi-provider-cloudscale.
 */

{
  apiGroup: 'infrastructure.cluster.x-k8s.io',
  CloudscaleCluster(name): {
    apiVersion: '%s/v1beta2' % $.apiGroup,
    kind: 'CloudscaleCluster',
    metadata: {
      name: name,
    },
  },
  CloudscaleClusterTemplate(name): {
    apiVersion: '%s/v1beta2' % $.apiGroup,
    kind: 'CloudscaleClusterTemplate',
    metadata: {
      name: name,
    },
  },
  CloudscaleMachineTemplate(name): {
    apiVersion: '%s/v1beta2' % $.apiGroup,
    kind: 'CloudscaleMachineTemplate',
    metadata: {
      name: name,
    },
  },
}
