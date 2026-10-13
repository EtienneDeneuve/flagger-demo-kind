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
    --code-bg: #0e0c0a;
  }
  section {
    background: var(--graphite);
    color: var(--text-on-dark);
    font-family: 'Outfit', system-ui, sans-serif;
    padding: 62px 72px 55px;
    font-size: 25px;
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
  h1 { color: var(--paper); font-size: 54px; line-height: 1.06; margin: 14px 0 22px; }
  h2 { color: var(--paper); font-size: 42px; margin: 10px 0 24px; line-height: 1.12; }
  h3 { color: var(--paper); font-size: 23px; margin: 0 0 10px; font-weight: 600; }
  p, li { color: var(--text-muted-on-dark); line-height: 1.4; }
  strong { color: var(--paper); font-weight: 600; }
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
    font-size: 28px;
    line-height: 1.35;
    color: var(--text-muted-on-dark);
    max-width: 1010px;
  }
  .accent { color: var(--copper); }
  .mark {
    font-family: 'Cormorant Garamond', Georgia, serif;
    font-weight: 700;
    color: var(--paper);
    letter-spacing: -0.01em;
  }
  .rule { border-top: 1px solid var(--border-on-dark); margin: 24px 0; }
  .steps { display: flex; align-items: stretch; gap: 14px; margin-top: 44px; }
  .step {
    flex: 1;
    border: 1px solid var(--border-on-dark);
    border-radius: 6px;
    padding: 22px 15px;
    text-align: center;
    font-size: 21px;
    background: var(--graphite-soft);
    color: var(--paper);
    font-weight: 600;
  }
  .step.hot {
    border-color: var(--copper);
    background: color-mix(in srgb, var(--copper) 12%, var(--graphite-soft));
    color: var(--copper);
  }
  .arrow { font-size: 24px; align-self: center; color: var(--text-subtle-on-dark); }
  .bottom {
    position: absolute;
    bottom: 67px;
    left: 73px;
    font-size: 17px;
    color: var(--text-subtle-on-dark);
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
  }
  .cells { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 28px; }
  .cell {
    background: var(--graphite-soft);
    border: 1px solid var(--border-on-dark);
    border-radius: 6px;
    padding: 20px 23px;
    min-height: 123px;
  }
  .cell .name {
    color: var(--copper);
    font-size: 13px;
    letter-spacing: 0.12em;
    font-weight: 600;
    text-transform: uppercase;
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
  }
  .cell p { margin: 9px 0 0; font-size: 19px; }
  .timeline { display: grid; grid-template-columns: 1.15fr 1.15fr 1.15fr; gap: 16px; margin-top: 42px; }
  .phase {
    border-top: 4px solid var(--copper);
    background: var(--graphite-soft);
    padding: 21px 20px 19px;
    border-radius: 0 0 6px 6px;
    min-height: 172px;
  }
  .phase.warning { border-color: var(--copper-deep); }
  .phase.muted { border-color: var(--paper-muted); }
  .phase .time {
    font-size: 28px;
    color: var(--paper);
    font-weight: 700;
    margin-bottom: 14px;
    letter-spacing: -0.02em;
  }
  .phase p { margin: 0; font-size: 20px; }
  .caption {
    font-size: 18px;
    color: var(--text-subtle-on-dark);
    margin-top: 25px;
  }
  .demo {
    display: grid;
    grid-template-columns: 90px 1fr auto;
    align-items: center;
    gap: 20px;
    border-bottom: 1px solid var(--border-on-dark);
    padding: 22px 0;
  }
  .num {
    color: var(--copper);
    font-size: 34px;
    font-weight: 700;
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
  }
  .demo .text { font-size: 22px; }
  .demo .detail { display: block; color: var(--text-subtle-on-dark); font-size: 16px; margin-top: 7px; }
  .cmd {
    font-family: 'IBM Plex Mono', ui-monospace, monospace;
    background: var(--code-bg);
    color: var(--copper);
    border: 1px solid var(--border-on-dark);
    border-radius: 4px;
    padding: 11px 16px;
    font-size: 17px;
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

<div class="bottom"><span class="mark">ÉD</span> &nbsp;·&nbsp; Gateway API · Prometheus · Podinfo &nbsp;·&nbsp; TP Mac</div>

---

<div class="eyebrow">01 / Architecture</div>

## Le trafic devient un signal de décision.

<div class="cells">
  <div class="cell"><div class="name">Cilium</div><p>Connectivité Kubernetes : le réseau, pas la stratégie de release.</p></div>
  <div class="cell"><div class="name">Envoy Gateway + Gateway API</div><p>Un <strong>HTTPRoute</strong> et des poids de backends pour piloter l'exposition.</p></div>
  <div class="cell"><div class="name">Flagger</div><p>Observe le Deployment, orchestre la canary, gère promotion et rollback.</p></div>
  <div class="cell"><div class="name">Prometheus</div><p>Mesure le taux de réponses 5xx de la <strong>version canary</strong>.</p></div>
</div>

<p class="caption">Pas de service mesh additionnel. Flagger crée la route ; Envoy applique ; Prometheus mesure.</p>

---

<div class="eyebrow">02 / Parcours · 60 minutes</div>

## Trois expériences, un seul cluster.

<div class="timeline">
  <div class="phase"><div class="time">00–25 min</div><h3>Comprendre & promouvoir</h3><p>Bootstrap, HTTPRoute, trafic progressif 25 % → 50 %.</p></div>
  <div class="phase warning"><div class="time">25–40 min</div><h3>Casser sans crasher</h3><p>Des 5xx réels déclenchent un rollback sur métrique.</p></div>
  <div class="phase muted"><div class="time">40–55 min</div><h3>Segmenter la beta</h3><p>Routage sélectif sur <code>x-canary: always</code>.</p></div>
</div>

<p class="caption">55–60 min : débrief, limites de la démo et implications GitOps. Préchauffer les images avant la séance.</p>

---

<div class="eyebrow">03 / Les manipulations</div>

## Ce qu'on va voir dans le cluster.

<div class="demo"><div class="num">01</div><div class="text"><strong>Promotion automatique</strong><span class="detail">Le contrôleur augmente les poids puis valide la nouvelle version.</span></div><div class="cmd">make good</div></div>
<div class="demo"><div class="num">02</div><div class="text"><strong>Rollback en quelques cycles</strong><span class="detail">Le SLI 5xx dépasse 5 % : la primary conserve le trafic.</span></div><div class="cmd">make fail</div></div>
<div class="demo"><div class="num">03</div><div class="text"><strong>A/B ciblé par header</strong><span class="detail">Le groupe beta voit la canary pendant l'analyse.</span></div><div class="cmd">make ab</div></div>

<p class="caption">À garder ouvert : <code>make port</code> · <code>make traffic</code> · <code>make status</code> · <code>make browser</code></p>
