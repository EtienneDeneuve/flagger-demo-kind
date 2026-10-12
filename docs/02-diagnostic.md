# Diagnostic rapide

## Le Mac n'accede pas a l'IP LoadBalancer de la Gateway

Comportement attendu avec Docker Desktop : le reseau Kind vit dans une VM Linux. Utiliser `make port`, puis `curl -H 'Host: podinfo.local' http://127.0.0.1:8080/`. Ne pas modifier `/etc/hosts` ni le routage macOS.

## Pas de HTTPRoute/podinfo

```bash
kubectl config current-context
kubectl -n flagger-system logs deployment/flagger --tail=150
kubectl -n flagger-demo describe canary/podinfo
kubectl -n flagger-demo get gateway/lab-gateway -o yaml
```

Vérifier que Flagger a `meshProvider=gatewayapi:v1`, que le Gateway `lab-gateway` est Accepted et que les CRDs Gateway API v1 sont presentes. Il ne faut pas appliquer soi-meme de HTTPRoute `podinfo`.

## Métriques absentes / "no values found"

```bash
kubectl -n flagger-demo get pods -l app=podinfo -o wide
kubectl -n flagger-system logs deploy/prometheus-lab --tail=80
kubectl -n flagger-system get cm prometheus-lab-config -o yaml
make metrics
```

Dans Prometheus, tester d'abord `up{job="podinfo-canary"}`, puis `http_requests_total{job="podinfo-canary"}`. Une canary a 0 replica entre deux deploiements : il est donc **normal** de ne pas avoir de serie. Pendant `Progressing`, laisser quelques dizaines de secondes pour obtenir au moins deux scrapes et verifier que `make traffic` n'affiche pas de `?`.

## Canary Failed avant la démo 2

Verifier que `make traffic` tourne et que le tunnel Envoy est actif. Ne pas confondre les retours HTTP 503 (route non prete) avec les 5xx applicatifs Podinfo. Regarder la configuration et le resultat du `MetricTemplate` dans Prometheus et les evenements du Canary.

## "Port 8080 already in use"

Un `kubectl port-forward` est deja actif ; l'arreter dans son terminal, puis relancer `make port`. Le script occupe 8080 localement.

## Le reset ne marche pas

Chaque scenario doit demarrer apres la phase `Succeeded` ou `Failed` du precedent. Rejouer `make up` sur le cluster ne reinitialise pas les images de Flagger en cours. Pour repartir de zero : `make cleanup && make up`.

## Verifier le binaire Podinfo

La source d'image Podinfo definit `CMD ["./podinfo"]`, que Kubernetes remplace si l'on definit `args`. Le manifest de ce repo definit donc explicitement `command: ["./podinfo"]`. Sans cela, le pod ne demarre pas.