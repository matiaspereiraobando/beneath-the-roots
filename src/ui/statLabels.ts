import { TUNING } from '../data/tuning';
import type { TowerDefinition } from '../data/types';
import type { GameState } from '../state/GameState';

export function getSatietyEffect(state: GameState): { text: string; color: string } {
  const starvePct = Math.round((1 - TUNING.queenStarveFireMult) * 100);
  const spawnPct = Math.round((TUNING.queenWellFedSpawnMult - 1) * 100);

  if (state.queenSatiety <= TUNING.queenStarveThreshold) {
    if (state.phase === 'wave') {
      return { text: `Starving: towers -${starvePct}% fire`, color: '#cc6644' };
    }
    return { text: 'Starving: feed before wave', color: '#cc6644' };
  }
  if (state.queenSatiety >= TUNING.queenWellFedThreshold) {
    if (state.phase === 'build') {
      return { text: `Well fed: spawn +${spawnPct}%`, color: '#8baa44' };
    }
    return { text: 'Well fed: full fire rate', color: '#8baa44' };
  }
  return { text: 'Satiety OK', color: '#8a7a6a' };
}

export function formatTowerStats(state: GameState, tower: TowerDefinition): string {
  const stats = state.getTowerStats(tower);
  const fireMult = state.getFireRateMultiplier();
  const aura = state.getAuraBuff(tower);
  const gland = TUNING.towerStats.gland;

  if (tower.type === 'gland') {
    const dmgPct = Math.round((gland.auraDamage ?? 0) * 100);
    const firePct = Math.round((gland.auraFireRate ?? 0) * 100);
    return `Aura rng ${Math.round(stats.range)}\n+${dmgPct}% dmg +${firePct}% fire`;
  }

  const effDmg = stats.damage * (1 + aura.damage);
  const effFire = stats.fireRate * fireMult * (1 + aura.fireRate);
  const dps = effDmg * effFire;
  const debuff = fireMult < 1 ? ' (queen debuff)' : '';

  const lines = [
    `${effDmg.toFixed(0)} dmg  ${effFire.toFixed(1)}/s  ~${dps.toFixed(0)} dps${debuff}`,
    `range ${Math.round(stats.range)}  soldier +${TUNING.soldierDpsBonus} dmg +${Math.round(TUNING.soldierFireRateBonus * 100)}% fire`,
  ];

  if (tower.type === 'crusher' && stats.splashRadius) {
    lines.push(`splash ${stats.splashRadius}`);
  } else if (tower.type === 'needle' && stats.pierce) {
    lines.push(`pierce ${stats.pierce}`);
  }

  return lines.join('\n');
}
