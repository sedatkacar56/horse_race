// strategies.js - Racing Strategy Assignment System

function assignRacingStrategies_sedat(horses) {
  // Get finish line from RACE_PARAMS or default
  const finishLine = window.RACE_PARAMS?.fl || 4500;
  const START_X = 50;
  
  // === STEP 1: calculate averages ===
  const avg = {
    speed:  horses.reduce((a,b)=>a+b.stats.baseSpeed,0) / horses.length,
    stamina:horses.reduce((a,b)=>a+b.stats.stamina,0) / horses.length,
    sprint: horses.reduce((a,b)=>a+b.stats.sprint,0) / horses.length
  };

  const raceLength = finishLine - START_X;
  const isShort = raceLength < 5000;
  const isLong  = raceLength > 8000;

  // === STEP 2: calculate suitability scores for each strategy ===
  const scores = horses.map(h => {
    const r = {
      speed:   h.stats.baseSpeed / avg.speed,
      stamina: h.stats.stamina   / avg.stamina,
      sprint:  h.stats.sprint    / avg.sprint
    };
    return {
      horse: h,
      scores: {
        FRONT_RUNNER: r.speed * 1.5 + r.stamina * 0.8 - r.sprint * 0.3,
        PRESSER:      r.speed * 1.1 + r.stamina * 1.0 + r.sprint * 0.8,
        STALKER:      3 - (Math.abs(r.speed-1) + Math.abs(r.stamina-1) + Math.abs(r.sprint-1)),
        CLOSER:       r.sprint * 1.6 + r.stamina * 1.1 - r.speed * 0.4
      }
    };
  });

  // === STEP 3: guarantee an equal mix across strategies ===
  const STRATS = ['FRONT_RUNNER','PRESSER','STALKER','CLOSER'];
  const assigned = new Map();
  const used     = new Set();
  const n        = horses.length;

  // helper: pick the best remaining horse for a given strategy
  function bestHorseFor(strategy) {
    const pick = scores
      .filter(s => !used.has(s.horse))
      .map(s => ({ horse: s.horse, score: s.scores[strategy] }))
      .sort((a,b) => b.score - a.score)[0];
    return pick || null;
  }

  // If <= 4 horses, give each a different strategy first
  if (n <= STRATS.length) {
    for (let i = 0; i < n; i++) {
      const st = STRATS[i];
      const pick = bestHorseFor(st);
      if (pick) { assigned.set(pick.horse, st); used.add(pick.horse); }
    }
  } else {
    // Equal target per strategy (base), remainder spread by strength
    const base = Math.floor(n / STRATS.length);
    let rem    = n % STRATS.length;

    const stratStrength = STRATS.map(st => {
      const top = scores.map(s => s.scores[st]).sort((a,b)=>b-a)[0] ?? -Infinity;
      return { st, top };
    }).sort((a,b) => b.top - a.top);

    const targets = {};
    STRATS.forEach(st => targets[st] = base);
    for (let i = 0; i < rem; i++) targets[stratStrength[i].st] += 1;

    function assignedPer(st) {
      let c = 0; for (const [,v] of assigned) if (v === st) c++; return c;
    }

    for (const st of STRATS) {
      while (assignedPer(st) < targets[st]) {
        const pick = bestHorseFor(st);
        if (!pick) break;
        assigned.set(pick.horse, st);
        used.add(pick.horse);
      }
    }

    scores.forEach(s => {
      if (!assigned.has(s.horse)) {
        const best = Object.entries(s.scores).sort((a,b)=>b[1]-a[1])[0][0];
        assigned.set(s.horse, best);
        used.add(s.horse);
      }
    });
  }

  horses.forEach(h => { h.strategy = assigned.get(h) || h.strategy; });

  // === STEP 4: apply tuned strategy parameters ===
  horses.forEach(h => {
    const r = {
      speed:   h.stats.baseSpeed / avg.speed,
      stamina: h.stats.stamina   / avg.stamina,
      sprint:  h.stats.sprint    / avg.sprint
    };

    switch(h.strategy) {
      case 'FRONT_RUNNER':
        h.strategyParams = {
          earlyPace: isLong ? 0.98 : (isShort ? 0.98 : 0.93),
          midPace:   isLong ? 0.90 : (isShort ? 0.93 : 0.88),
          latePace:  isLong ? 0.65 : (isShort ? 0.90 : 0.82),
          energyDrain: isLong ? 1.25 : 1.15,
          kickPhase: isLong ? 0.90 : 0.85
        };
        break;
      case 'PRESSER':
        h.strategyParams = {
          earlyPace: isLong ? 0.85 : (isShort ? 0.90 : 0.93),
          midPace:   isLong ? 0.90 : (isShort ? 0.90 : 0.95),
          latePace:  isLong ? 1.00 : 1.02,
          energyDrain: 1.1,
          kickPhase: 0.72,
          kickMult: 1.08,
          surgeWindow: 0.15,
          gapTrigger: 0.8
        };
        break;
      case 'STALKER':
        h.strategyParams = {
          earlyPace: isLong ? 0.80 : (isShort ? 0.80 : 0.80),
          midPace:   isLong ? 0.92 : 0.88,
          latePace:  isLong ? 1.12 : 1.08,
          energyDrain: 0.93,
          kickPhase: 0.72
        };
        break;
      case 'CLOSER':
        h.strategyParams = {
          earlyPace: isShort ? 0.78 : 0.68,
          midPace:   isLong ? 0.80 : 0.76,
          latePace:  isLong ? 1.35 : 1.22,
          energyDrain: 0.70,
          kickPhase: isShort ? 0.75 : 0.80
        };
        break;
    }
  });

  // === STEP 5: log for debugging ===
  const dist = {};
  horses.forEach(h => dist[h.strategy] = (dist[h.strategy]||0)+1);
  console.log('📊 Final strategy distribution:', dist);
  horses.forEach(h => console.log(`🐴 ${h.name.padEnd(20)} → ${h.strategy}`));
  
  // Show summary if function exists
  if (typeof showStrategySummary === 'function') {
    showStrategySummary(horses);
  }
  
  return horses; // Return for chaining
}





// Make it available globally
window.assignRacingStrategies_sedat = assignRacingStrategies_sedat;
console.log('✅ strategies.js loaded successfully');




function assignRacingStrategies_old(horses) {


  // === STEP 1: calculate averages ===
  const avg = {
    speed:  horses.reduce((a,b)=>a+b.stats.baseSpeed,0) / horses.length,
    stamina:horses.reduce((a,b)=>a+b.stats.stamina,0) / horses.length,
    sprint: horses.reduce((a,b)=>a+b.stats.sprint,0) / horses.length
  };

  const raceLength = finishLine - 50;
  const isShort = raceLength < 3000;
  const isLong  = raceLength > 6000;

  // === STEP 2: calculate suitability scores for each strategy ===
  const scores = horses.map(h => {
    const r = {
      speed:   h.stats.baseSpeed / avg.speed,
      stamina: h.stats.stamina   / avg.stamina,
      sprint:  h.stats.sprint    / avg.sprint
    };
    return {
      horse: h,
      scores: {
        FRONT_RUNNER: r.speed * 1.5 + r.stamina * 0.8 - r.sprint * 0.3,
        PRESSER:      r.speed * 1.1 + r.stamina * 1.0 + r.sprint * 0.8,
        STALKER:      3 - (Math.abs(r.speed-1) + Math.abs(r.stamina-1) + Math.abs(r.sprint-1)),
        CLOSER:       r.sprint * 1.6 + r.stamina * 1.1 - r.speed * 0.4
      }
    };
  });

    // === STEP 3EQUAL: guarantee an equal mix across strategies ===
  const STRATS = ['FRONT_RUNNER','PRESSER','STALKER','CLOSER'];
  const assigned = new Map();
  const used     = new Set();
  const n        = horses.length;

  // helper: pick the best remaining horse for a given strategy
  function bestHorseFor(strategy) {
    const pick = scores
      .filter(s => !used.has(s.horse))
      .map(s => ({ horse: s.horse, score: s.scores[strategy] }))
      .sort((a,b) => b.score - a.score)[0];
    return pick || null;
  }

  // If <= 4 horses, give each a different strategy first
  if (n <= STRATS.length) {
    for (let i = 0; i < n; i++) {
      const st = STRATS[i];
      const pick = bestHorseFor(st);
      if (pick) { assigned.set(pick.horse, st); used.add(pick.horse); }
    }
  } else {
    // Equal target per strategy (base), remainder spread by strength
    const base = Math.floor(n / STRATS.length); // e.g. 16 -> 4 each
    let rem    = n % STRATS.length;             // leftovers to distribute

    // Which strategies are strongest overall (by their top available score)?
    const stratStrength = STRATS.map(st => {
      const top = scores.map(s => s.scores[st]).sort((a,b)=>b-a)[0] ?? -Infinity;
      return { st, top };
    }).sort((a,b) => b.top - a.top);

    const targets = {};
    STRATS.forEach(st => targets[st] = base);
    for (let i = 0; i < rem; i++) targets[stratStrength[i].st] += 1;

    // helper: how many already assigned to st?
    function assignedPer(st) {
      let c = 0; for (const [,v] of assigned) if (v === st) c++; return c;
    }

    // Fill each bucket up to its target
    for (const st of STRATS) {
      while (assignedPer(st) < targets[st]) {
        const pick = bestHorseFor(st);
        if (!pick) break;
        assigned.set(pick.horse, st);
        used.add(pick.horse);
      }
    }

    // Anything left unassigned → drop into their personal best strategy
    scores.forEach(s => {
      if (!assigned.has(s.horse)) {
        const best = Object.entries(s.scores).sort((a,b)=>b[1]-a[1])[0][0];
        assigned.set(s.horse, best);
        used.add(s.horse);
      }
    });
  }

  // Write back chosen strategies
  horses.forEach(h => { h.strategy = assigned.get(h) || h.strategy; });

  // === STEP 5: apply tuned strategy parameters ===
  horses.forEach(h => {
    const r = {
      speed:   h.stats.baseSpeed / avg.speed,
      stamina: h.stats.stamina   / avg.stamina,
      sprint:  h.stats.sprint    / avg.sprint
    };

    switch(h.strategy) {
      case 'FRONT_RUNNER':
        h.strategyParams = {
          earlyPace: isLong ? 0.88 : (isShort ? 0.98 : 0.93),
          midPace:   isLong ? 0.83 : 0.88,
          latePace:  isLong ? 0.78 : 0.82,
          energyDrain: isLong ? 1.25 : 1.15,
          kickPhase: isLong ? 0.90 : 0.85
        };
        break;
      case 'PRESSER':
        h.strategyParams = {
          earlyPace: 0.82,
          midPace:   isLong ? 0.88 : 0.90,
          latePace:  isLong ? 1.05 : 1.02,
          energyDrain: 1.1,
          kickPhase: 0.72,
          kickMult: 1.08,
          surgeWindow: 0.15,
          gapTrigger: 0.8
        };
        break;
      case 'STALKER':
        h.strategyParams = {
          earlyPace: 0.80,
          midPace:   isLong ? 0.92 : 0.88,
          latePace:  isLong ? 1.12 : 1.08,
          energyDrain: 0.93,
          kickPhase: 0.72
        };
        break;
      case 'CLOSER':
        h.strategyParams = {
          earlyPace: isShort ? 0.78 : 0.68,
          midPace:   isLong ? 0.78 : 0.76,
          latePace:  isLong ? 1.35 : 1.22,
          energyDrain: 0.70,
          kickPhase: isShort ? 0.75 : 0.80
        };
        break;
    }
  });

  // === STEP 6: log for debugging ===
  const dist = {};
  horses.forEach(h => dist[h.strategy] = (dist[h.strategy]||0)+1);
  console.log('📊 Final strategy distribution:', dist);
  horses.forEach(h => console.log(`🐴 ${h.name.padEnd(20)} → ${h.strategy}`));
  showStrategySummary(horses);
}

// Make it available globally
window.assignRacingStrategies_old = assignRacingStrategies_old;
console.log('✅ assignRacingStrategies_old.js loaded successfully');




// ============================================
// UPDATE YOUR updateHorses() FUNCTION:
// Replace the physics calculation part with this
// ============================================

function updateHorses_sedat(dt) {
  if (!raceActive) return;

  // Precompute leader once per tick
  const leaderXGlobal = Math.max(...horses.map(hh => hh.x));

  horses.forEach(h => {
    const prog = Math.min(1, (h.x - 50) / (finishLine - 50)); // 0..1 race progress
    
    // ✅ ADD THESE TWO LINES RIGHT HERE:
    const totalF = FURLONGS_TOTAL;                     // total furlongs this race (computed earlier)
    const curF   = Math.max(0, Math.min(totalF, (h.x - START_X) / PPF)); // clamp 0..totalF
    // --- Phase pacing (uses strategyParams + kickPhase) ---
    const sp = h.strategyParams || {};
    const earlyPace = sp.earlyPace ?? 0.9;
    const midPace   = sp.midPace   ?? 0.9;
    const latePace  = sp.latePace  ?? 0.95;
    const kickPhase = sp.kickPhase ?? 0.80;

    let paceTarget;
    if (prog < 0.33) {
      paceTarget = earlyPace;
    } else if (prog < Math.min(0.70, kickPhase)) {
      paceTarget = midPace;
    } else if (prog >= kickPhase) {
      paceTarget = latePace; // KICK phase
    } else {
      paceTarget = midPace;
    }

    // --- Base speed with strategy phase ---
    const baseSpeed = h.stats.baseSpeed * paceTarget;

    // --- Stamina effect (ramps up with distance) ---
// === 1) Harsher stamina scaling for long trips ===
// make stamina cost grow with total distance; hurts early leaders in marathons
const longness = Math.min(1, Math.max(0, (totalF - 12) / 12)); // 0 at <=12f, →1 by 24f
const staminaPower = 1.8 + 0.6 * longness; // was ~1.8; now up to 2.4 on 24f
const staminaEffect = Math.pow(h.stats.stamina, staminaPower * prog);

    // --- Fatigue/pressure from leading (leader pays a tax) ---
    const isLeading = h.x >= leaderXGlobal - 5;
    const energyDrain = sp.energyDrain ?? 1.1;
    // Start applying leader pressure around halfway; scale with prog
    const tired = 1 - h.stats.fatigue * Math.max(0, prog - 0.5) * (isLeading ? energyDrain : 1.0);

    // --- Random variance (soft-capped to keep packs tight) ---
    const rawJitter = (Math.random() - 0.5) * (h.stats.variance ?? 0.1);
    const jitter = Math.max(-0.08, Math.min(0.08, rawJitter)); // clamp ±0.08

    // --- Initial speed before kick/surge logic ---
    let s = baseSpeed * staminaEffect * tired + jitter;

    // === 2) Leader drag that ramps with distance and race progress ===
// Compute second place X to measure "clear lead"
const sortedX = horses.map(o => o.x).sort((a,b)=>b-a);
const leaderX = sortedX[0] || 0;
const secondX = sortedX[1] || leaderX;
const oneLengthPx = Math.max(1, (h.stats.baseSpeed || 1) * 12);
const leadGapLengths = (leaderX - secondX) / oneLengthPx;

// If you're the leader, pay a growing tax, bigger in long races and late in race
if (h.x >= leaderX - 5) {
  // base leader tax grows with progress and longness; extra if clear by >2L
  const baseLeaderTax = 1 + 0.10*prog + 0.15*longness;     // up to ~+0.25
  const clearLeadTax  = leadGapLengths > 2 ? 0.05*Math.min(4,(leadGapLengths-2)) : 0;
  const leaderDrag    = 1 - Math.min(0.28, (baseLeaderTax - 1) + clearLeadTax); // cap 28%
  s *= leaderDrag;
} else {
  // === 3) Pack/drafting assist for everyone NOT leading ===
  // Find nearest horse ahead to draft off (within ~1–4 lengths)
  let nearestAheadPx = Infinity;
  for (const o of horses) {
    if (o === h) continue;
    if (o.x > h.x) nearestAheadPx = Math.min(nearestAheadPx, o.x - h.x);
  }
  const nearestAheadL = nearestAheadPx / oneLengthPx;

  if (nearestAheadL >= 1 && nearestAheadL <= 4) {
    // Base drafting boost; slightly stronger in long races and mid-late phases
    const draftBase = 0.02 + 0.03*longness + 0.02*Math.min(1, (prog-0.3)/0.5); // up to ~7%
    // Stalkers get more value from draft
    const stratBonus = h.strategy === 'STALKER' ? 0.02 : 0.0;
    s *= 1 + Math.min(0.10, draftBase + stratBonus);
  }

  // Gentle elastic catch-up if you’re >4 lengths behind leader, bigger in long races and late
  const gapBehindLeaderL = (leaderX - h.x) / oneLengthPx;
  if (gapBehindLeaderL > 4) {
    const elastic = Math.min(0.12, 0.03 + 0.05*longness + 0.05*Math.max(0, prog-0.5));
    s *= (1 + elastic);
  }
}


    // --- Kick bursts (your existing logic, kept) ---
    if (h._kickCooldown == null) h._kickCooldown = 0;
    if (h._kickTimer == null)    h._kickTimer    = 0;
    h._kickCooldown -= dt;
    h._kickTimer = Math.max(0, h._kickTimer - dt);

    if (h._kickCooldown <= 0 && Math.random() < 0.015 * h.stats.kick) {
      h._kickTimer = 0.6 + 0.8 * h.stats.kick;
      h._kickCooldown = 2.0 + Math.random() * 2.0;
    }

    if (prog > 0.82 && h._kickTimer === 0 && !h._lateKickUsed) {
      h._kickTimer = 0.7 + 0.9 * h.stats.kick;
      h._lateKickUsed = true;
    }

    const kickBoost = h._kickTimer > 0
      ? 1 + (0.20 + 0.80 * h.stats.kick) * (1 - prog * 0.3)
      : 1;
    s *= kickBoost;

    // --- STALKER: stronger mid/late catch-up + drafting + late steadiness ---
if (h.strategy === 'STALKER') {
  const behindPx = leaderXGlobal - h.x;

  // heuristic "length" size in px (based on each horse's baseline)
  const oneLengthPx = Math.max(1, (h.stats.baseSpeed || 1) * 12);
  const gapLengths  = behindPx / oneLengthPx;

  // (A) Mid-race catch-up (buffed: up to +12%)
  if (prog > 0.26 && prog < 0.78 && gapLengths > 0.6) {
    // base + scaled by how far back; capped
    const gain = Math.min(0.12, 0.03 + 0.035 * (gapLengths - 0.6));
    s *= (1 + gain);
  }

  // (B) Drafting when within ~1–4 lengths of any horse ahead (buffed)
  const nearestAheadPx = horses.reduce((min, o) => {
    if (o === h || o.x <= h.x) return min;
    const d = o.x - h.x;
    return d < min ? d : min;
  }, Infinity);

  if (nearestAheadPx < 4 * oneLengthPx) {
    // closer = more slipstream
    const slip = Math.max(0, 1 - (nearestAheadPx / (4 * oneLengthPx))); // 0..1
    s *= 1 + 0.02 + slip * 0.05; // up to ~+7%
    
    // Slingshot in the closing 6f if still behind a little
    if ((totalF - curF) <= 6 && gapLengths > 0.3 && gapLengths < 2.5) {
      s *= 1.03;
    }
  }

  // (C) Late steadiness (buffed)
  if (prog > 0.80) {
    s *= 1.07;
  }

  // (D) Mid-late fatigue guard (keeps them from sagging)
  if (prog > 0.55 && prog < 0.88) {
    s *= 1.03;
  }
}


    // --- PRESSER late surge (gap-aware) ---
    if (h.strategy === 'PRESSER') {
      const surgeWindow  = sp.surgeWindow ?? 0.18; // last 18% of race
      const gapTrigger   = sp.gapTrigger  ?? 0.6;  // lengths behind before surge assist
      const kickMult     = sp.kickMult    ?? 1.12; // base kick multiplier for pressers

      // Start building earlier for pressers
      if (prog >= (sp.kickPhase ?? 0.70)) {
        s *= kickMult;

        // If still behind in final surge window, add capped catch-up
        if (prog >= (1 - surgeWindow)) {
          // convert px gap to "lengths"
          const gapPx = leaderXGlobal - h.x;
          const oneLengthPx = Math.max(1, (h.stats.baseSpeed || 1) * 12); // heuristic
          const gapLengths = gapPx / oneLengthPx;

          if (gapLengths > gapTrigger) {
            // smooth, bounded catch-up: stronger if farther back, capped
            const catchUp = Math.min(1.12, 1 + 0.06 * Math.tanh(gapLengths - gapTrigger));
            s *= catchUp;
          }
        }
      }
    }

// --- CLOSER: long-run ramping boost from 12f to race end (targeting 24f scale) ---
// --- 4) CLOSER: long-run ramping boost from 12f to end, stronger near 24f ---
if (h.strategy === 'CLOSER') {
  if (curF >= 12 && totalF > 12) {
    const longPhase = Math.min(1, (curF - 12) / Math.max(1, (totalF - 12))); // 0..1
    // scale with longness; allow bigger ceiling on true marathons
    const maxLongBoost = (0.35 + 0.20*longness) * (0.85 + 0.3 * (h.stats.finalBoost || 1));
    const longMult = 1 + longPhase * maxLongBoost;
    s *= Math.min(longMult, 1.55); // hard cap ~+55%
  }
}


    if (h._finalBoostUsed && prog > 0.9) {
      s *= 1.0 - (prog - 0.9) * 0.15; // taper off
    }

    // --- Safety floors & motion ---
    h.speed = Math.max(0.8, s);
    h.x += h.speed;
    h.step += h.speed * 0.08;

    // --- Finish detection (unchanged) ---
    if (h.x >= finishLine && !h.finished) {
      h.finished = true;
      h.finishTime = performance.now();
      finishOrder.push({
        name: h.name,
        lane: h.lane,
        color: h.color,
        position: finishOrder.length + 1,
        strategy: h.strategy,
        handicap: h.handicap
      });

      if (finishOrder.length === horses.length) {
        raceFinished = true;
        raceActive = false;
        showResults();
      }
    }

    if (h.finished && h.x > finishLine + 100) {
      h.speed *= 0.95;
    }
  });

  refreshLeaderboard();
  updateRaceResults();
}

// Make it available globally
window.updateHorses_sedat = updateHorses_sedat;
console.log('✅ updateHorses_sedat loaded successfully');





function updateHorses_new(dt) {
  if (!raceActive) return;

  // Precompute leader once per tick
  const leaderXGlobal = Math.max(...horses.map(hh => hh.x));

  horses.forEach(h => {
    const prog = Math.min(1, (h.x - 50) / (finishLine - 50)); // 0..1 race progress
    
    const totalF = FURLONGS_TOTAL;
    const curF = Math.max(0, Math.min(totalF, (h.x - START_X) / PPF));
    
    // --- Phase pacing (uses strategyParams + kickPhase) ---
    const sp = h.strategyParams || {};
    const earlyPace = sp.earlyPace ?? 0.9;
    const midPace   = sp.midPace   ?? 0.9;
    const latePace  = sp.latePace  ?? 0.95;
    const kickPhase = sp.kickPhase ?? 0.80;

    let paceTarget;
    if (prog < 0.33) {
      paceTarget = earlyPace;
    } else if (prog < Math.min(0.70, kickPhase)) {
      paceTarget = midPace;
    } else if (prog >= kickPhase) {
      paceTarget = latePace;
    } else {
      paceTarget = midPace;
    }

    // --- Base speed with strategy phase ---
    const baseSpeed = h.stats.baseSpeed * paceTarget;

    // === STAMINA: More realistic (less punishing) ===
    const longness = Math.min(1, Math.max(0, (totalF - 12) / 12));
    const staminaPower = 1.5 + 0.4 * longness; // REDUCED from 1.8 + 0.6
    const staminaEffect = Math.pow(h.stats.stamina, staminaPower * prog);

    // === LEADER FATIGUE: Much lighter penalty ===
    const isLeading = h.x >= leaderXGlobal - 5;
    const energyDrain = sp.energyDrain ?? 1.1;
    const tired = 1 - h.stats.fatigue * Math.max(0, prog - 0.65) * (isLeading ? energyDrain * 0.6 : 0.8); 
    // Changed: Start fatigue later (0.65 vs 0.5), reduced multiplier (0.6 vs 1.0)

    // --- Random variance (tighter) ---
    const rawJitter = (Math.random() - 0.5) * (h.stats.variance ?? 0.1);
    const jitter = Math.max(-0.05, Math.min(0.05, rawJitter)); // TIGHTER: ±0.05 instead of ±0.08

    // --- Initial speed ---
    let s = baseSpeed * staminaEffect * tired + jitter;

    // === LEADER DRAG: REDUCED significantly ===
    const sortedX = horses.map(o => o.x).sort((a,b)=>b-a);
    const leaderX = sortedX[0] || 0;
    const secondX = sortedX[1] || leaderX;
    const oneLengthPx = Math.max(1, (h.stats.baseSpeed || 1) * 12);
    const leadGapLengths = (leaderX - secondX) / oneLengthPx;

    if (h.x >= leaderX - 5) {
      // REDUCED leader penalties
      const baseLeaderTax = 1 + 0.04*prog + 0.06*longness; // Was 0.10 and 0.15
      const clearLeadTax  = leadGapLengths > 3 ? 0.02*Math.min(3,(leadGapLengths-3)) : 0; // Was >2 and 0.05
      const leaderDrag    = 1 - Math.min(0.15, (baseLeaderTax - 1) + clearLeadTax); // Cap at 15% not 28%
      s *= leaderDrag;
    } else {
      // === DRAFTING: REDUCED significantly ===
      let nearestAheadPx = Infinity;
      for (const o of horses) {
        if (o === h) continue;
        if (o.x > h.x) nearestAheadPx = Math.min(nearestAheadPx, o.x - h.x);
      }
      const nearestAheadL = nearestAheadPx / oneLengthPx;

      // REDUCED drafting benefit
      if (nearestAheadL >= 1.5 && nearestAheadL <= 3) { // Narrower window: 1.5-3 instead of 1-4
        const draftBase = 0.01 + 0.015*longness; // HALVED: was 0.02 + 0.03
        const stratBonus = h.strategy === 'STALKER' ? 0.01 : 0.0; // HALVED
        s *= 1 + Math.min(0.04, draftBase + stratBonus); // Cap at 4% not 10%
      }

      // === ELASTIC CATCH-UP: REMOVED for horses 4+ lengths back ===
      // Commented out to prevent pack bunching
      // const gapBehindLeaderL = (leaderX - h.x) / oneLengthPx;
      // if (gapBehindLeaderL > 4) {
      //   const elastic = Math.min(0.12, 0.03 + 0.05*longness + 0.05*Math.max(0, prog-0.5));
      //   s *= (1 + elastic);
      // }
    }

    // --- Kick bursts (unchanged) ---
    if (h._kickCooldown == null) h._kickCooldown = 0;
    if (h._kickTimer == null)    h._kickTimer    = 0;
    h._kickCooldown -= dt;
    h._kickTimer = Math.max(0, h._kickTimer - dt);

    if (h._kickCooldown <= 0 && Math.random() < 0.015 * h.stats.kick) {
      h._kickTimer = 0.6 + 0.8 * h.stats.kick;
      h._kickCooldown = 2.0 + Math.random() * 2.0;
    }

    if (prog > 0.82 && h._kickTimer === 0 && !h._lateKickUsed) {
      h._kickTimer = 0.7 + 0.9 * h.stats.kick;
      h._lateKickUsed = true;
    }

    const kickBoost = h._kickTimer > 0
      ? 1 + (0.20 + 0.80 * h.stats.kick) * (1 - prog * 0.3)
      : 1;
    s *= kickBoost;

    // === STALKER: REDUCED catch-up mechanics ===
    if (h.strategy === 'STALKER') {
      const behindPx = leaderXGlobal - h.x;
      const gapLengths = behindPx / oneLengthPx;

      // REDUCED mid-race catch-up
      if (prog > 0.30 && prog < 0.75 && gapLengths > 1.5) { // Stricter conditions
        const gain = Math.min(0.06, 0.015 + 0.02 * (gapLengths - 1.5)); // HALVED gains
        s *= (1 + gain);
      }

      // REDUCED drafting bonus
      const nearestAheadPx = horses.reduce((min, o) => {
        if (o === h || o.x <= h.x) return min;
        const d = o.x - h.x;
        return d < min ? d : min;
      }, Infinity);

      if (nearestAheadPx < 3 * oneLengthPx) { // Tighter range
        const slip = Math.max(0, 1 - (nearestAheadPx / (3 * oneLengthPx)));
        s *= 1 + 0.01 + slip * 0.025; // HALVED: was 0.02 + 0.05
        
        // Slingshot only in final 4f (not 6f)
        if ((totalF - curF) <= 4 && gapLengths > 0.5 && gapLengths < 2) {
          s *= 1.015; // REDUCED from 1.03
        }
      }

      // Late steadiness REDUCED
      if (prog > 0.82) { // Later trigger
        s *= 1.03; // REDUCED from 1.07
      }

      // Mid-late guard REMOVED
      // if (prog > 0.55 && prog < 0.88) {
      //   s *= 1.03;
      // }
    }

    // === PRESSER: Slightly reduced ===
    if (h.strategy === 'PRESSER') {
      const surgeWindow  = sp.surgeWindow ?? 0.18;
      const gapTrigger   = sp.gapTrigger  ?? 0.8; // Stricter: was 0.6
      const kickMult     = sp.kickMult    ?? 1.06; // REDUCED from 1.08

      if (prog >= (sp.kickPhase ?? 0.72)) {
        s *= kickMult;

        if (prog >= (1 - surgeWindow)) {
          const gapPx = leaderXGlobal - h.x;
          const gapLengths = gapPx / oneLengthPx;

          if (gapLengths > gapTrigger) {
            const catchUp = Math.min(1.08, 1 + 0.04 * Math.tanh(gapLengths - gapTrigger)); // REDUCED
            s *= catchUp;
          }
        }
      }
    }

    // === CLOSER: REDUCED long-run boost ===
    if (h.strategy === 'CLOSER') {
      if (curF >= 14 && totalF > 14) { // Start later: 14f not 12f
        const longPhase = Math.min(1, (curF - 14) / Math.max(1, (totalF - 14)));
        const maxLongBoost = (0.25 + 0.15*longness) * (0.80 + 0.25 * (h.stats.finalBoost || 1)); // REDUCED
        const longMult = 1 + longPhase * maxLongBoost;
        s *= Math.min(longMult, 1.35); // Cap at +35% not +55%
      }
    }

    if (h._finalBoostUsed && prog > 0.9) {
      s *= 1.0 - (prog - 0.9) * 0.15;
    }

    // --- Safety floors & motion ---
    h.speed = Math.max(0.8, s);
    h.x += h.speed;
    h.step += h.speed * 0.08;

    // --- Finish detection ---
    if (h.x >= finishLine && !h.finished) {
      h.finished = true;
      h.finishTime = performance.now();
      finishOrder.push({
        name: h.name,
        lane: h.lane,
        color: h.color,
        position: finishOrder.length + 1,
        strategy: h.strategy,
        handicap: h.handicap
      });

      if (finishOrder.length === horses.length) {
        raceFinished = true;
        raceActive = false;
        showResults();
      }
    }

    if (h.finished && h.x > finishLine + 100) {
      h.speed *= 0.95;
    }
  });

  refreshLeaderboard();
  updateRaceResults();
}

window.updateHorses_new = updateHorses_new;
console.log('✅ updateHorses_new loaded successfully');

