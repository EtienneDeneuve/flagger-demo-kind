---
marp: true
html: true
size: 16:9
paginate: true
theme: default
style: |
  @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Space+Grotesk:wght@500;600;700&display=swap');
  section {
    background: #0A1422;
    color: #F4F7FA;
    font-family: 'DM Sans', 'Aptos', sans-serif;
    padding: 62px 72px 55px;
    font-size: 25px;
  }
  section::after { color: #6F8196; font-size: 17px; right: 67px; bottom: 32px; }
  h1, h2, h3 { font-family: 'Space Grotesk', 'Aptos Display', sans-serif; letter-spacing: -.035em; }
  h1 { color: #F4F7FA; font-size: 55px; line-height: 1.05; margin: 14px 0 22px; }
  h2 { color: #F4F7FA; font-size: 44px; margin: 10px 0 24px; }
  h3 { color: #F4F7FA; font-size: 24px; margin: 0 0 10px; }
  p, li { color: #BFCAD7; line-height: 1.35; }
  strong { color: #F4F7FA; }
  code { color: #62E8CF; font-size: .8em; background: #162A3E; padding: .08em .26em; border-radius: 5px; }
  .eyebrow { color: #5CE0C5; font-size: 16px; font-weight: 700; letter-spacing: .19em; text-transform: uppercase; }
  .lead { font-size: 29px; line-height: 1.3; color: #BFCAD7; max-width: 1010px; }
  .accent { color: #5CE0C5; }
  .rule { border-top: 1px solid #304459; margin: 24px 0; }
  .steps { display: flex; align-items: stretch; gap: 14px; margin-top: 44px; }
  .step { flex: 1; border: 1px solid #304459; border-radius: 13px; padding: 22px 15px; text-align: center; font-size: 22px; background: #0F2030; color: #EAF1F6; font-weight: 600; }
  .step.hot { border-color: #36CCB4; background: #0D2A31; color: #79F3DD; }
  .arrow { font-size: 25px; align-self: center; color: #5D8897; }
  .bottom { position: absolute; bottom: 67px; left: 73px; font-size: 19px; color: #8C9DAE; }
  .kpi { display: inline-block; padding: 8px 15px; border: 1px solid #35C8AE; border-radius: 100px; color: #76ECD5; font-size: 17px; font-weight: 600; }
  .cells { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 28px; }
  .cell { background: #102339; border: 1px solid #264157; border-radius: 13px; padding: 20px 23px; min-height: 123px; }
  .cell .name { color: #6CEBD5; font-size: 16px; letter-spacing: .10em; font-weight: 700; text-transform: uppercase; }
  .cell p { margin: 9px 0 0; font-size: 19px; }
  .timeline { display: grid; grid-template-columns: 1.15fr 1.15fr 1.15fr; gap: 16px; margin-top: 42px; }
  .phase { border-top: 5px solid #61DAC6; background: #102237; padding: 21px 20px 19px; border-radius: 0 0 13px 13px; min-height: 172px; }
  .phase.warning { border-color: #E6AA6D; }
  .phase.purple { border-color: #9C9CFF; }
  .phase .time { font-size: 31px; color: #F5F8FA; font-weight: 700; margin-bottom: 17px; }
  .phase p { margin: 0; font-size: 21px; }
  .caption { font-size: 19px; color: #95AAB8; margin-top: 25px; }
  .demo { display: grid; grid-template-columns: 90px 1fr auto; align-items: center; gap: 20px; border-bottom: 1px solid #2A4456; padding: 22px 0; }
  .num { color: #5CE0C5; font-size: 37px; font-weight: 700; }
  .demo .text { font-size: 23px; }
  .demo .detail { display: block; color: #90A4B7; font-size: 17px; margin-top: 7px; }
  .cmd { font-family: Menlo, Monaco, monospace; background: #152F3F; color: #70E9CE; border: 1px solid #2D5361; border-radius: 9px; padding: 11px 16px; font-size: 18px; }
---

<!-- _class: opening -->
<div class="eyebrow">PLATFORM ENGINEERING · HANDS-ON · 60 MIN</div>

# Déployer sans parier.

<p class="lead"><strong>Flagger</strong> valide chaque nouvelle version sur du vrai trafic et décide : <span class="accent">promouvoir</span>, <span class="accent">stopper</span>, ou <span class="accent">revenir en arrière</span>.</p>

<div class="steps">
  <div class="step">Kind</div><div class="arrow">→</div>
  <div class="step">Cilium</div><div class="arrow">→</div>
  <div class="step">Envoy Gateway</div><div class="arrow">→</div>
  <div class="step hot">Flagger</div>
</div>

<div class="bottom">Gateway API · Prometheus · Podinfo &nbsp;&nbsp; | &nbsp;&nbsp; TP reproductible sur Mac</div>

---

<div class="eyebrow">01 / ARCHITECTURE</div>

## Le trafic devient un signal de décision.

<div class="cells">
  <div class="cell"><div class="name">Cilium</div><p>Connectivité Kubernetes : le réseau, pas la stratégie de release.</p></div>
  <div class="cell"><div class="name">Envoy Gateway + Gateway API</div><p>Un <strong>HTTPRoute</strong> et des poids de backends pour piloter l'exposition.</p></div>
  <div class="cell"><div class="name">Flagger</div><p>Observe le Deployment, orchestre la canary, gère promotion et rollback.</p></div>
  <div class="cell"><div class="name">Prometheus</div><p>Mesure le taux de réponses 5xx de la <strong>version canary</strong>.</p></div>
</div>

<p class="caption">Pas de service mesh additionnel. Flagger crée la route ; Envoy applique ; Prometheus mesure.</p>

---

<div class="eyebrow">02 / PARCOURS · 60 MINUTES</div>

## Trois expériences, un seul cluster.

<div class="timeline">
  <div class="phase"><div class="time">00–25 min</div><h3>Comprendre & promouvoir</h3><p>Bootstrap, HTTPRoute, trafic progressif de 10 % à 50 %.</p></div>
  <div class="phase warning"><div class="time">25–40 min</div><h3>Casser sans crasher</h3><p>Des 5xx réels déclenchent un rollback sur métrique.</p></div>
  <div class="phase purple"><div class="time">40–55 min</div><h3>Segmenter la beta</h3><p>Routage sélectif sur <code>x-canary: always</code>.</p></div>
</div>

<p class="caption">55–60 min : débrief, limites de la démo et implications GitOps. Préchauffer les images avant la séance.</p>

---

<div class="eyebrow">03 / LES MANIPULATIONS</div>

## Ce qu'on va voir dans le cluster.

<div class="demo"><div class="num">01</div><div class="text"><strong>Promotion automatique</strong><span class="detail">Le contrôleur augmente les poids puis valide la nouvelle version.</span></div><div class="cmd">make good</div></div>
<div class="demo"><div class="num">02</div><div class="text"><strong>Rollback en quelques cycles</strong><span class="detail">Le SLI 5xx dépasse 5 % : la primary conserve le trafic.</span></div><div class="cmd">make fail</div></div>
<div class="demo"><div class="num">03</div><div class="text"><strong>A/B ciblé par header</strong><span class="detail">Le groupe beta voit la canary pendant l'analyse.</span></div><div class="cmd">make ab</div></div>

<p class="caption">À garder ouvert : <code>make port</code> · <code>make traffic</code> · <code>make status</code></p>