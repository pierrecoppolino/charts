{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "kafka.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified zookeeper name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "kafka.zookeeper.fullname" -}}
{{- if .Values.zookeeper.fullnameOverride -}}
{{- .Values.zookeeper.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "zookeeper" .Values.zookeeper.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
 Create the name of the service account to use
 */}}
{{- define "kafka.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Kafka image name
*/}}
{{- define "kafka.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container auto-discovery image)
*/}}
{{- define "kafka.externalAccess.autoDiscovery.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.externalAccess.autoDiscovery.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "kafka.volumePermissions.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.volumePermissions.image "global" .Values.global) }}
{{- end -}}

{{/*
Create a default fully qualified Kafka exporter name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "kafka.metrics.kafka.fullname" -}}
  {{- printf "%s-exporter" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{/*
 Create the name of the service account to use for Kafka exporter pods
 */}}
{{- define "kafka.metrics.kafka.serviceAccountName" -}}
{{- if .Values.metrics.kafka.serviceAccount.create -}}
    {{ default (include "kafka.metrics.kafka.fullname" .) .Values.metrics.kafka.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.metrics.kafka.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the proper Kafka exporter image name
*/}}
{{- define "kafka.metrics.kafka.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.metrics.kafka.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper JMX exporter image name
*/}}
{{- define "kafka.metrics.jmx.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.metrics.jmx.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "kafka.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.externalAccess.autoDiscovery.image .Values.volumePermissions.image .Values.metrics.kafka.image .Values.metrics.jmx.image) "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Storage Class
*/}}
{{- define "kafka.storageClass" -}}
{{/*
Helm 2.11 supports the assignment of a value to a variable defined in a different scope,
but Helm 2.9 and 2.10 does not support it, so we need to implement this if-else logic.
*/}}
{{- if .Values.global -}}
    {{- if .Values.global.storageClass -}}
        {{- if (eq "-" .Values.global.storageClass) -}}
            {{- printf "storageClassName: \"\"" -}}
        {{- else }}
            {{- printf "storageClassName: %s" .Values.global.storageClass -}}
        {{- end -}}
    {{- else -}}
        {{- if .Values.persistence.storageClass -}}
              {{- if (eq "-" .Values.persistence.storageClass) -}}
                  {{- printf "storageClassName: \"\"" -}}
              {{- else }}
                  {{- printf "storageClassName: %s" .Values.persistence.storageClass -}}
              {{- end -}}
        {{- end -}}
    {{- end -}}
{{- else -}}
    {{- if .Values.persistence.storageClass -}}
        {{- if (eq "-" .Values.persistence.storageClass) -}}
            {{- printf "storageClassName: \"\"" -}}
        {{- else }}
            {{- printf "storageClassName: %s" .Values.persistence.storageClass -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return true if authentication via SASL should be configured for client communications
*/}}
{{- define "kafka.client.saslAuthentication" -}}
{{- $saslProtocols := list "sasl" "sasl_tls" -}}
{{- if or (has .Values.auth.clientProtocol $saslProtocols) (has .Values.auth.externalClientProtocol $saslProtocols) (has .Values.additionalListeners.protocol $saslProtocols)  -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if authentication via SASL should be configured for inter-broker communications
*/}}
{{- define "kafka.interBroker.saslAuthentication" -}}
{{- $saslProtocols := list "sasl" "sasl_tls" -}}
{{- if has .Values.auth.interBrokerProtocol $saslProtocols -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if encryption via TLS for client connections should be configured
*/}}
{{- define "kafka.client.tlsEncryption" -}}
{{- $tlsProtocols := list "tls" "mtls" "sasl_tls" -}}
{{- if (has .Values.auth.clientProtocol $tlsProtocols) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the configured value for the external client protocol, defaults to the same value as clientProtocol
*/}}
{{- define "kafka.externalClientProtocol" -}}
    {{- coalesce .Values.auth.externalClientProtocol .Values.auth.clientProtocol -}}
{{- end -}}

{{/*
Return true if encryption via TLS for external client connections should be configured
*/}}
{{- define "kafka.externalClient.tlsEncryption" -}}
{{- $tlsProtocols := list "tls" "mtls" "sasl_tls" -}}
{{- if (has (include "kafka.externalClientProtocol" . ) $tlsProtocols) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if encryption via TLS for inter broker communication connections should be configured
*/}}
{{- define "kafka.interBroker.tlsEncryption" -}}
{{- $tlsProtocols := list "tls" "mtls" "sasl_tls" -}}
{{- if (has .Values.auth.interBrokerProtocol $tlsProtocols) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if encryption via TLS should be configured
*/}}
{{- define "kafka.tlsEncryption" -}}
{{- if or (include "kafka.client.tlsEncryption" .) (include "kafka.interBroker.tlsEncryption" .) (include "kafka.externalClient.tlsEncryption" .) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the type of listener
Usage:
{{ include "kafka.listenerType" }}
*/}}
{{- define "kafka.listenerType" -}}
{{- if eq .protocol "plaintext" -}}
PLAINTEXT
{{- else if or (eq .protocol "tls") (eq .protocol "mtls") -}}
SSL
{{- else if eq .protocol "sasl_tls" -}}
SASL_SSL
{{- else if eq .protocol "sasl" -}}
SASL_PLAINTEXT
{{- end -}}
{{- end -}}

{{/*
Return listeners
Usage:
{{ include "kafka.computeListeners" }}
*/}}
{{- define "kafka.computeListeners" -}}
{{ $listeners := ""}}
{{- if not (empty .Values.listeners)  -}}
{{- $listeners = join "," .Values.listeners -}}
{{- else if .Values.externalAccess.enabled -}}
{{- $listeners = printf "%s%v,%s%v,%s%v" "INTERNAL://:" .Values.service.ports.internal "CLIENT://:" .Values.service.ports.client "EXTERNAL://:" .Values.service.ports.external }}
{{- else -}}
{{- $listeners = printf "%s%v,%s%v" "INTERNAL://:" .Values.service.ports.internal "CLIENT://:" .Values.service.ports.client }}
{{- end -}}
{{- if .Values.additionalListeners.enabled -}}
{{- $listeners = printf "%s,%s://:%v" $listeners .Values.additionalListeners.listener .Values.additionalListeners.port -}}
{{- end -}}
{{- printf "%s" $listeners -}}
{{- end -}}

{{/*
Return listeners
Usage:
{{ include "kafka.computeProtocolMap" }}
*/}}
{{- define "kafka.computeProtocolMap" -}}
{{ $protocolMap := "test" }}
{{- if not (empty .Values.advertisedListeners)  -}}
{{- $protocolMap = .Values.advertisedListeners | quote -}}
{{- else -}}
{{- $interBrokerProtocol := include "kafka.listenerType" (dict "protocol" .Values.auth.interBrokerProtocol) -}}
{{- $clientProtocol := include "kafka.listenerType" (dict "protocol" .Values.auth.clientProtocol) -}}
{{- if .Values.externalAccess.enabled -}}
{{- $externalClientProtocol := include "kafka.listenerType" (dict "protocol" (include "kafka.externalClientProtocol" . )) -}}
{{- $protocolMap = printf "%s%s,%s%s,%s%s" "INTERNAL:" $interBrokerProtocol "CLIENT:" $clientProtocol "EXTERNAL:" $externalClientProtocol -}}
{{- else -}}
{{- $protocolMap = printf "%s%s,%s%s" "INTERNAL:" $interBrokerProtocol "CLIENT:" $clientProtocol -}}
{{- end -}}
{{- end -}}
{{- if .Values.additionalListeners.enabled -}}
{{- $additionalListenerProtocol := include "kafka.listenerType" (dict "protocol" .Values.additionalListeners.protocol) -}}
{{- $protocolMap = printf "%s,%s:%s" $protocolMap .Values.additionalListeners.listener $additionalListenerProtocol -}}
{{- end -}}
{{- printf "%s" $protocolMap -}}
{{- end -}}

{{/*
Return the Kafka JAAS credentials secret
*/}}
{{- define "kafka.jaasSecretName" -}}
{{- $secretName := .Values.auth.sasl.jaas.existingSecret -}}
{{- if $secretName -}}
    {{- printf "%s" (tpl $secretName $) -}}
{{- else -}}
    {{- printf "%s-jaas" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a JAAS credentials secret object should be created
*/}}
{{- define "kafka.createJaasSecret" -}}
{{- $secretName := .Values.auth.sasl.jaas.existingSecret -}}
{{- if and (or (include "kafka.client.saslAuthentication" .) (include "kafka.interBroker.saslAuthentication" .) (and .Values.zookeeper.auth.enabled .Values.auth.sasl.jaas.zookeeperUser)) (empty $secretName) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a TLS credentials secret object should be created
*/}}
{{- define "kafka.createTlsSecret" -}}
{{- if and (include "kafka.tlsEncryption" .) (empty .Values.auth.tls.existingSecrets) (eq .Values.auth.tls.type "pem") .Values.auth.tls.autoGenerated }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the Kafka configuration configmap
*/}}
{{- define "kafka.configmapName" -}}
{{- if .Values.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-configuration" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "kafka.createConfigmap" -}}
{{- if and .Values.config (not .Values.existingConfigmap) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the Kafka log4j ConfigMap name.
*/}}
{{- define "kafka.log4j.configMapName" -}}
{{- if .Values.existingLog4jConfigMap -}}
    {{- printf "%s" (tpl .Values.existingLog4jConfigMap $) -}}
{{- else -}}
    {{- printf "%s-log4j-configuration" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a log4j ConfigMap object should be created.
*/}}
{{- define "kafka.log4j.createConfigMap" -}}
{{- if and .Values.log4j (not .Values.existingLog4jConfigMap) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the SASL mechanism to use for the Kafka exporter to access Kafka
The exporter uses a different nomenclature so we need to do this hack
*/}}
{{- define "kafka.metrics.kafka.saslMechanism" -}}
{{- $saslMechanisms := .Values.auth.sasl.mechanisms }}
{{- if contains "scram-sha-512" $saslMechanisms }}
    {{- print "scram-sha512" -}}
{{- else if contains "scram-sha-256" $saslMechanisms }}
    {{- print "scram-sha256" -}}
{{- else -}}
    {{- print "plain" -}}
{{- end -}}
{{- end -}}

{{/*
Return the Kafka configuration configmap
*/}}
{{- define "kafka.metrics.jmx.configmapName" -}}
{{- if .Values.metrics.jmx.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.metrics.jmx.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-jmx-configuration" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "kafka.metrics.jmx.createConfigmap" -}}
{{- if and .Values.metrics.jmx.enabled .Values.metrics.jmx.config (not .Values.metrics.jmx.existingConfigmap) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Check if there are rolling tags in the images
*/}}
{{- define "kafka.checkRollingTags" -}}
{{- include "common.warnings.rollingTag" .Values.image }}
{{- include "common.warnings.rollingTag" .Values.externalAccess.autoDiscovery.image }}
{{- include "common.warnings.rollingTag" .Values.metrics.kafka.image }}
{{- include "common.warnings.rollingTag" .Values.metrics.jmx.image }}
{{- include "common.warnings.rollingTag" .Values.volumePermissions.image }}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "kafka.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "kafka.validateValues.authProtocols" .) -}}
{{- $messages := append $messages (include "kafka.validateValues.nodePortListLength" .) -}}
{{- $messages := append $messages (include "kafka.validateValues.externalAccessServiceType" .) -}}
{{- $messages := append $messages (include "kafka.validateValues.externalAccessAutoDiscoveryRBAC" .) -}}
{{- $messages := append $messages (include "kafka.validateValues.externalAccessAutoDiscoveryIPsOrNames" .) -}}
{{- $messages := append $messages (include "kafka.validateValues.externalAccessServiceList" (dict "element" "loadBalancerIPs" "context" .)) -}}
{{- $messages := append $messages (include "kafka.validateValues.externalAccessServiceList" (dict "element" "loadBalancerNames" "context" .)) -}}
{{- $messages := append $messages (include "kafka.validateValues.externalAccessServiceList" (dict "element" "loadBalancerAnnotations" "context" . )) -}}
{{- $messages := append $messages (include "kafka.validateValues.saslMechanisms" .) -}}
{{- $messages := append $messages (include "kafka.validateValues.tlsSecrets" .) -}}
{{- $messages := append $messages (include "kafka.validateValues.tlsSecrets.length" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - Authentication protocols for Kafka */}}
{{- define "kafka.validateValues.authProtocols" -}}
{{- $authProtocols := list "plaintext" "tls" "mtls" "sasl" "sasl_tls" -}}
{{- if or (not (has .Values.auth.clientProtocol $authProtocols)) (not (has .Values.auth.interBrokerProtocol $authProtocols)) (not (has (include "kafka.externalClientProtocol" . ) $authProtocols)) -}}
kafka: auth.clientProtocol auth.externalClientProtocol auth.interBrokerProtocol
    Available authentication protocols are "plaintext", "tls", "mtls", "sasl" and "sasl_tls"
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - number of replicas must be the same as NodePort list */}}
{{- define "kafka.validateValues.nodePortListLength" -}}
{{- $replicaCount := int .Values.replicaCount }}
{{- $nodePortListLength := len .Values.externalAccess.service.nodePorts }}
{{- if and (or .Values.externalAccess.enabled .Values.additionalListeners.enabled) (not .Values.externalAccess.autoDiscovery.enabled) (not (eq $replicaCount $nodePortListLength )) (eq .Values.externalAccess.service.type "NodePort") -}}
kafka: .Values.externalAccess.service.nodePorts
    Number of replicas and nodePort array length must be the same. Currently: replicaCount = {{ $replicaCount }} and nodePorts = {{ $nodePortListLength }}
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - service type for external access */}}
{{- define "kafka.validateValues.externalAccessServiceType" -}}
{{- if and (not (eq .Values.externalAccess.service.type "NodePort")) (not (eq .Values.externalAccess.service.type "LoadBalancer")) -}}
kafka: externalAccess.service.type
    Available service type for external access are NodePort or LoadBalancer.
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - RBAC should be enabled when autoDiscovery is enabled */}}
{{- define "kafka.validateValues.externalAccessAutoDiscoveryRBAC" -}}
{{- if and (or .Values.externalAccess.enabled .Values.additionalListeners.enabled) .Values.externalAccess.autoDiscovery.enabled (not .Values.rbac.create ) }}
kafka: rbac.create
    By specifying "externalAccess.enabled=true" and "externalAccess.autoDiscovery.enabled=true"
    an initContainer will be used to auto-detect the external IPs/ports by querying the
    K8s API. Please note this initContainer requires specific RBAC resources. You can create them
    by specifying "--set rbac.create=true".
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - LoadBalancerIPs or LoadBalancerNames should be set when autoDiscovery is disabled */}}
{{- define "kafka.validateValues.externalAccessAutoDiscoveryIPsOrNames" -}}
{{- $loadBalancerNameListLength := len .Values.externalAccess.service.loadBalancerNames -}}
{{- $loadBalancerIPListLength := len .Values.externalAccess.service.loadBalancerIPs -}}
{{- if and (or .Values.externalAccess.enabled .Values.additionalListeners.enabled) (eq .Values.externalAccess.service.type "LoadBalancer") (not .Values.externalAccess.autoDiscovery.enabled) (eq $loadBalancerNameListLength 0) (eq $loadBalancerIPListLength 0) }}
kafka: externalAccess.service.loadBalancerNames or externalAccess.service.loadBalancerIPs
    By specifying "externalAccess.enabled=true", "externalAccess.autoDiscovery.enabled=false" and
    "externalAccess.service.type=LoadBalancer" at least one of externalAccess.service.loadBalancerNames
    or externalAccess.service.loadBalancerIPs  must be set and the length of those arrays must be equal
    to the number of replicas.
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - number of replicas must be the same as loadBalancerIPs list */}}
{{- define "kafka.validateValues.externalAccessServiceList" -}}
{{- $replicaCount := int .context.Values.replicaCount }}
{{- $listLength := len (get .context.Values.externalAccess.service .element) -}}
{{- if and (or .context.Values.externalAccess.enabled .context.Values.additionalListeners.enabled) (not .context.Values.externalAccess.autoDiscovery.enabled) (eq .context.Values.externalAccess.service.type "LoadBalancer") (gt $listLength 0) (not (eq $replicaCount $listLength)) }}
kafka: externalAccess.service.{{ .element }}
    Number of replicas and {{ .element }} array length must be the same. Currently: replicaCount = {{ $replicaCount }} and {{ .element }} = {{ $listLength }}
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - SASL mechanisms must be provided when using SASL */}}
{{- define "kafka.validateValues.saslMechanisms" -}}
{{- if and (or (.Values.auth.clientProtocol | regexFind "sasl") (.Values.auth.interBrokerProtocol | regexFind "sasl") (and .Values.zookeeper.auth.enabled .Values.auth.sasl.jaas.zookeeperUser)) (not .Values.auth.sasl.mechanisms) }}
kafka: auth.sasl.mechanisms
    The SASL mechanisms are required when either auth.clientProtocol or auth.interBrokerProtocol use SASL or Zookeeper user is provided.
{{- end }}
{{- if not (contains .Values.auth.sasl.interBrokerMechanism .Values.auth.sasl.mechanisms) }}
kafka: auth.sasl.mechanisms
    auth.sasl.interBrokerMechanism must be provided and it should be one of the specified mechanisms at auth.saslMechanisms
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - Secrets containing TLS certs must be provided when TLS authentication is enabled */}}
{{- define "kafka.validateValues.tlsSecrets" -}}
{{- if and (include "kafka.tlsEncryption" .) (eq .Values.auth.tls.type "jks") (empty .Values.auth.tls.existingSecrets) }}
kafka: auth.tls.existingSecrets
    A secret containing the Kafka JKS keystores and truststore is required
    when TLS encryption in enabled and TLS format is "JKS"
{{- else if and (include "kafka.tlsEncryption" .) (eq .Values.auth.tls.type "pem") (empty .Values.auth.tls.existingSecrets) (not .Values.auth.tls.autoGenerated) }}
kafka: auth.tls.existingSecrets
    A secret containing the Kafka TLS certificates and keys is required
    when TLS encryption in enabled and TLS format is "PEM"
{{- end -}}
{{- end -}}

{{/* Validate values of Kafka - The number of secrets containing TLS certs should be equal to the number of replicas */}}
{{- define "kafka.validateValues.tlsSecrets.length" -}}
{{- $replicaCount := int .Values.replicaCount }}
{{- if and (include "kafka.tlsEncryption" .) (not (empty .Values.auth.tls.existingSecrets)) }}
{{- $existingSecretsLength := len .Values.auth.tls.existingSecrets }}
{{- if ne $replicaCount $existingSecretsLength }}
kafka: .Values.auth.tls.existingSecrets
    Number of replicas and existingSecrets array length must be the same. Currently: replicaCount = {{ $replicaCount }} and existingSecrets = {{ $existingSecretsLength }}
{{- end -}}
{{- end -}}
{{- end -}}
