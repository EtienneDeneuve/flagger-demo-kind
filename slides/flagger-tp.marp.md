---
marp: true
html: true
size: 16:9
paginate: true
theme: default
style: |
  /* Étienne Deneuve — graphite / ivory / copper (aligné blog) */
  @import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@600;700&family=IBM+Plex+Mono:wght@400;500;600&family=Outfit:wght@400;500;600;700&display=swap');
  :root {
    --ink: #151819;
    --graphite: #111416;
    --graphite-soft: #1b1e20;
    --paper: #f3efe7;
    --paper-elevated: #faf8f3;
    --paper-muted: #e8e3d8;
    --text-on-dark: #f7f3ec;
    --text-muted-on-dark: #cdd0cf;
    --text-subtle-on-dark: #9aa0a3;
    --copper: #f0aa78;
    --copper-deep: #a54822;
    --border-on-dark: rgba(243, 239, 231, 0.16);
    --border-strong: rgba(243, 239, 231, 0.28);
    --danger: #f97066;
    --ok: #6dd3a8;
    --code-bg: #0e0c0a;
  }
  section {
    background: var(--graphite);
    color: var(--text-on-dark);
    font-family: 'Outfit', system-ui, sans-serif;
    padding: 58px 68px 52px;
    font-size: 24px;
  }
  section::after {
    color: var(--text-subtle-on-dark);
    font-size: 16px;
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
    right: 67px;
    bottom: 32px;
  }
  h1, h2, h3 {
    font-family: 'Outfit', system-ui, sans-serif;
    letter-spacing: -0.02em;
    font-weight: 600;
  }
  h1 { color: var(--paper); font-size: 52px; line-height: 1.06; margin: 12px 0 18px; }
  h2 { color: var(--paper); font-size: 38px; margin: 8px 0 20px; line-height: 1.12; }
  h3 { color: var(--paper); font-size: 22px; margin: 0 0 8px; font-weight: 600; }
  p, li { color: var(--text-muted-on-dark); line-height: 1.38; }
  strong { color: var(--paper); font-weight: 600; }
  ul { margin: 8px 0 0; padding-left: 1.15em; }
  li { margin: 6px 0; }
  code {
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
    color: var(--copper);
    font-size: 0.82em;
    background: var(--code-bg);
    padding: 0.1em 0.3em;
    border-radius: 4px;
    border: 1px solid var(--border-on-dark);
  }
  .eyebrow {
    color: var(--copper);
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
    font-size: 14px;
    font-weight: 600;
    letter-spacing: 0.16em;
    text-transform: uppercase;
  }
  .lead {
    font-size: 26px;
    line-height: 1.35;
    color: var(--text-muted-on-dark);
    max-width: 1010px;
  }
  .accent { color: var(--copper); }
  .ok { color: var(--ok); }
  .bad { color: var(--danger); }
  .mark {
    font-family: 'Cormorant Garamond', Georgia, serif;
    font-weight: 700;
    color: var(--paper);
    letter-spacing: -0.01em;
  }
  .bottom {
    position: absolute;
    bottom: 62px;
    left: 68px;
    font-size: 16px;
    color: var(--text-subtle-on-dark);
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
  }
  .steps { display: flex; align-items: stretch; gap: 12px; margin-top: 36px; }
  .step {
    flex: 1;
    border: 1px solid var(--border-on-dark);
    border-radius: 6px;
    padding: 18px 12px;
    text-align: center;
    font-size: 19px;
    background: var(--graphite-soft);
    color: var(--paper);
    font-weight: 600;
  }
  .step.hot {
    border-color: var(--copper);
    background: color-mix(in srgb, var(--copper) 12%, var(--graphite-soft));
    color: var(--copper);
  }
  .arrow { font-size: 22px; align-self: center; color: var(--text-subtle-on-dark); }
  .cells { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-top: 22px; }
  .cells.three { grid-template-columns: 1fr 1fr 1fr; }
  .cell {
    background: var(--graphite-soft);
    border: 1px solid var(--border-on-dark);
    border-radius: 6px;
    padding: 16px 18px;
    min-height: 110px;
  }
  .cell .name {
    color: var(--copper);
    font-size: 12px;
    letter-spacing: 0.12em;
    font-weight: 600;
    text-transform: uppercase;
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
  }
  .cell p { margin: 8px 0 0; font-size: 18px; }
  .timeline { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 14px; margin-top: 28px; }
  .phase {
    border-top: 4px solid var(--copper);
    background: var(--graphite-soft);
    padding: 16px 16px 14px;
    border-radius: 0 0 6px 6px;
    min-height: 150px;
  }
  .phase.warning { border-color: var(--copper-deep); }
  .phase.muted { border-color: var(--paper-muted); }
  .phase .time {
    font-size: 24px;
    color: var(--paper);
    font-weight: 700;
    margin-bottom: 10px;
    letter-spacing: -0.02em;
  }
  .phase p { margin: 0; font-size: 18px; }
  .caption {
    font-size: 16px;
    color: var(--text-subtle-on-dark);
    margin-top: 18px;
  }
  .demo {
    display: grid;
    grid-template-columns: 70px 1fr auto;
    align-items: center;
    gap: 16px;
    border-bottom: 1px solid var(--border-on-dark);
    padding: 16px 0;
  }
  .num {
    color: var(--copper);
    font-size: 28px;
    font-weight: 700;
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
  }
  .demo .text { font-size: 20px; }
  .demo .detail { display: block; color: var(--text-subtle-on-dark); font-size: 15px; margin-top: 5px; }
  .cmd {
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
    background: var(--code-bg);
    color: var(--copper);
    border: 1px solid var(--border-on-dark);
    border-radius: 4px;
    padding: 9px 12px;
    font-size: 14px;
    white-space: nowrap;
  }
  .q {
    margin-top: 20px;
    padding: 14px 18px;
    border-left: 3px solid var(--copper);
    background: color-mix(in srgb, var(--copper) 8%, var(--graphite-soft));
    font-size: 20px;
    color: var(--paper);
  }
  .loop {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 10px;
    margin-top: 28px;
  }
  .loop .box {
    background: var(--graphite-soft);
    border: 1px solid var(--border-on-dark);
    border-radius: 6px;
    padding: 16px 14px;
    text-align: center;
  }
  .loop .box .n {
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
    color: var(--copper);
    font-size: 13px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
  }
  .loop .box p { margin: 10px 0 0; font-size: 17px; color: var(--paper); font-weight: 600; }
  .vs {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 18px;
    margin-top: 26px;
  }
  .vs .col {
    background: var(--graphite-soft);
    border-radius: 6px;
    padding: 20px 22px;
    border: 1px solid var(--border-on-dark);
  }
  .vs .col.good { border-color: color-mix(in srgb, var(--ok) 45%, var(--border-on-dark)); }
  .vs .col.fail { border-color: color-mix(in srgb, var(--danger) 45%, var(--border-on-dark)); }
  .vs .col h3 { margin-bottom: 12px; }
  .fileline {
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
    font-size: 15px;
    color: var(--copper);
    margin: 4px 0 12px;
  }
---

<!-- _class: opening -->
<div class="eyebrow">Platform engineering · hands-on · 60 min</div>

# Déployer sans parier.

<p class="lead"><strong>Flagger</strong> valide chaque nouvelle version sur du vrai trafic et décide : <span class="accent">promouvoir</span>, <span class="accent">stopper</span>, ou <span class="accent">revenir en arrière</span>.</p>

<div class="steps">
  <div class="step">Kind</div><div class="arrow">→</div>
  <div class="step">Cilium</div><div class="arrow">→</div>
  <div class="step">Envoy Gateway</div><div class="arrow">→</div>
  <div class="step hot">Flagger</div>
</div>

<div class="bottom"><span class="mark">ÉD</span> &nbsp;·&nbsp; Gateway API · Prometheus · Podinfo &nbsp;·&nbsp; YAML à appliquer (pas seulement <code>make</code>)</div>

---

<div class="eyebrow">01 / Problème</div>

## `Ready` ne veut pas dire « digne du trafic ».

<div class="vs">
  <div class="col good">
    <h3 class="ok">Ce que Kubernetes sait</h3>
    <ul>
      <li>Remplacer des pods (rolling update)</li>
      <li>Probes <code>/readyz</code> / <code>/healthz</code></li>
      <li>Garantir qu’un process écoute</li>
    </ul>
  </div>
  <div class="col fail">
    <h3 class="bad">Ce qu’il ne décide pas</h3>
    <ul>
      <li>Taux d’erreurs HTTP 5xx</li>
      <li>Latence / SLO métier</li>
      <li>Qui mérite 100&nbsp;% des utilisateurs</li>
    </ul>
  </div>
</div>

<div class="q">Question d’ouverture : un Deployment « Available » peut-il quand même ruiner la prod ?</div>

---

<div class="eyebrow">02 / Architecture</div>

## Qui fait quoi — une seule boucle.

<div class="cells">
  <div class="cell"><div class="name">Cilium</div><p>Connectivité pod ↔ pod. Le réseau, <strong>pas</strong> la stratégie de release.</p></div>
  <div class="cell"><div class="name">Envoy Gateway</div><p>Applique un <strong>HTTPRoute</strong> Gateway API : poids, matches, hostnames.</p></div>
  <div class="cell"><div class="name">Flagger</div><p>Observe le Deployment, crée/modifie la route, orchestre canary → promote / fail.</p></div>
  <div class="cell"><div class="name">Prometheus</div><p>SLI canary : taux de <strong>5xx</strong> sur <code>job=podinfo-canary</code> seulement.</p></div>
</div>

<p class="caption">Pas d’Istio. Flagger <strong>possède</strong> la HTTPRoute — ne pas en créer une à la main.</p>

---

<div class="eyebrow">03 / Boucle de contrôle</div>

## Tu changes l’app. Flagger change le trafic.

<div class="loop">
  <div class="box"><div class="n">1 · Toi</div><p>Patch Deployment<br/><code>manifests/tp/*</code></p></div>
  <div class="box"><div class="n">2 · Flagger</div><p>Nouveau hash<br/>→ scale canary</p></div>
  <div class="box"><div class="n">3 · Envoy</div><p>Poids / match<br/>HTTPRoute</p></div>
  <div class="box"><div class="n">4 · Prom</div><p>Verdict métrique<br/>promote / halt</p></div>
</div>

<p class="caption">Après <code>Succeeded</code> : primary = nouvelle version, canary weight = 0. Tu n’édites jamais la route à la main.</p>

<div class="q">Qui a écrit les <code>backendRefs</code> de la HTTPRoute ? (spoiler : pas vous)</div>

---

<div class="eyebrow">04 / Parcours · 60 min</div>

## Trois expériences, un seul cluster.

<div class="timeline">
  <div class="phase"><div class="time">00–25</div><h3>Lire &amp; promouvoir</h3><p>Canary YAML, patch V2, poids 25&nbsp;% → 50&nbsp;% → primary.</p></div>
  <div class="phase warning"><div class="time">25–40</div><h3>Casser sans crasher</h3><p>Pods Ready + 5xx HTTP → rollback. Primary intacte.</p></div>
  <div class="phase muted"><div class="time">40–55</div><h3>Cohorte beta</h3><p><code>apply</code> Canary A/B + V4. Header vs public.</p></div>
</div>

<p class="caption">55–60 : limites (pas GitOps / TLS / Envoy E2E). Images préchauffées <strong>avant</strong> la séance.</p>

---

<div class="eyebrow">05 / Poste de travail</div>

## Trois terminaux, toujours ouverts.

<div class="demo"><div class="num">T1</div><div class="text"><strong>Tunnel Envoy</strong><span class="detail">Sans <code>Host: podinfo.local</code> → 404. Réutilise :8080 s’il répond déjà.</span></div><div class="cmd">make port</div></div>
<div class="demo"><div class="num">T2</div><div class="text"><strong>Charge HTTP</strong><span class="detail"><code>.</code> = 2xx &nbsp; <code>x</code> = 5xx &nbsp; <code>?</code> = autre. Sans trafic, pas de <code>rate()</code> utile.</span></div><div class="cmd">make traffic</div></div>
<div class="demo"><div class="num">T3</div><div class="text"><strong>Tableau de bord</strong><span class="detail">Phase, poids canary, messages UI primary / target, events Halt.</span></div><div class="cmd">make status</div></div>

<p class="caption">Optionnel : <code>make browser</code> (proxy Host) · guide : <code>docs/05-tp-participant.md</code></p>

---

<div class="eyebrow">06 / TP 0 · Lire</div>

## Ouvrir les fichiers avant de taper.

<div class="cells">
  <div class="cell"><div class="name">manifests/05-canary.yaml</div><p><code>interval</code> 10s · <code>stepWeight</code> 25 · <code>maxWeight</code> 50 · seuil 5xx &lt; 5&nbsp;%</p></div>
  <div class="cell"><div class="name">manifests/tp/01-…v2.patch.yaml</div><p>Message UI + annotation <code>flagger-lab/revision</code> → <strong>nouveau hash</strong></p></div>
  <div class="cell"><div class="name">04-metrics.yaml</div><p>PromQL sur canary only · fenêtre <code>{{ interval }}</code> (pas 1m figé)</p></div>
  <div class="cell"><div class="name">HTTPRoute live</div><p><code>./lab kubectl -n flagger-demo get httproute podinfo -o yaml</code></p></div>
</div>

<div class="q">Sans changer l’annotation de révision, un second patch peut être un no-op. Pourquoi ?</div>

---

<div class="eyebrow">07 / TP 1 · Promotion</div>

## Une version saine gagne le trafic.

<p class="fileline">manifests/tp/01-promote-v2.patch.yaml</p>

```bash
./lab kubectl -n flagger-demo patch deploy/podinfo --type strategic \
  --patch-file manifests/tp/01-promote-v2.patch.yaml
```

<div class="cells three">
  <div class="cell"><div class="name">Observer</div><p>Phase <code>Progressing</code> · poids 25 puis 50 · UI <strong>V2 VALIDEE</strong></p></div>
  <div class="cell"><div class="name">Puis</div><p><code>Promoting</code> → copy template → primary · weight 0</p></div>
  <div class="cell"><div class="name">Réussite</div><p>Phase <code>Succeeded</code> · public = V2</p></div>
</div>

<p class="caption">Filet : <code>make good</code> (même YAML). Question : <em>quand</em> primary reçoit V2 ?</p>

---

<div class="eyebrow">08 / TP 2 · Rollback</div>

## Ready ≠ bon pour les utilisateurs.

<p class="fileline">02-degraded-v3.patch.yaml · puis fault injection canary only</p>

<div class="vs">
  <div class="col">
    <h3>Étape A — révision</h3>
    <p>Patch V3. Flagger scale une canary <strong>Ready</strong>.</p>
  </div>
  <div class="col fail">
    <h3>Étape B — panne HTTP</h3>
    <p><code>POST …/fault_injection/enable</code> sur <code>svc/podinfo-canary</code>. Probes intactes.</p>
  </div>
</div>

<ul>
  <li>Events : <code>Halt … error-rate &gt; 5</code> → <code>Failed</code></li>
  <li>Primary reste <strong>V2</strong> — ce n’est pas un <code>git revert</code></li>
  <li><strong>Pause ~15&nbsp;s</strong> avant le TP 3 (fenêtre Prometheus)</li>
</ul>

---

<div class="eyebrow">09 / TP 3 · A/B</div>

## Deux fichiers, deux concepts.

<div class="demo"><div class="num">A</div><div class="text"><strong>Stratégie de routage</strong><span class="detail">Canary en mode match header — plus de stepWeight, des <code>iterations</code>.</span></div><div class="cmd">apply 03-ab-canary.yaml</div></div>
<div class="demo"><div class="num">B</div><div class="text"><strong>Révision cohorte</strong><span class="detail">V4 BETA visible seulement avec <code>x-canary: always</code>.</span></div><div class="cmd">patch 03-revision-v4</div></div>

```bash
# pendant Progressing
curl -H 'Host: podinfo.local' -H 'x-canary: always' …/api/info   # → V4
curl -H 'Host: podinfo.local' …/api/info                         # → V2
```

<p class="caption">Après promote : le match disparaît. Tout le monde est sur primary.</p>

---

<div class="eyebrow">10 / Ce qu’on n’a pas fait</div>

## Limites volontaires du lab.

<div class="cells">
  <div class="cell"><div class="name">Hors périmètre</div><p>GitOps · TLS · NetworkPolicy · métriques Envoy bout-en-bout · alerting</p></div>
  <div class="cell"><div class="name">Métrique pédagogique</div><p>SLI app Podinfo, pas le mapping labels Envoy production</p></div>
  <div class="cell"><div class="name">Cible</div><p>macOS + moteur Docker · Kind isolé · MIT</p></div>
  <div class="cell"><div class="name">Prod</div><p>Combiner signaux upstream + app · fenêtres · timeouts · SLO</p></div>
</div>

<div class="q">Flagger n’est pas le processus de livraison — c’est le contrôle de qualité <em>là où le trafic rencontre</em> une nouvelle version.</div>

---

<div class="eyebrow">11 / À retenir</div>

## Une phrase pour demain matin.

<p class="lead" style="margin-top:36px">Tu déclenches une <strong>révision</strong> (YAML).<br/>Flagger décide du <strong>trafic</strong> (HTTPRoute + métriques).</p>

<div class="steps" style="margin-top:48px">
  <div class="step">patch / apply</div><div class="arrow">→</div>
  <div class="step">canary</div><div class="arrow">→</div>
  <div class="step">mesure</div><div class="arrow">→</div>
  <div class="step hot">promote | fail</div>
</div>

<div class="bottom">Repo · docs/05-tp-participant.md · docs/en/ · etienne.deneuve.xyz/projects/flagger-demo-kind</div>
