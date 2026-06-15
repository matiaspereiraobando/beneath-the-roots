import type { PathPoint } from '../data/types';

export class PathFollower {
  private segments: { start: PathPoint; end: PathPoint; length: number }[] = [];
  private totalLength = 0;

  constructor(path: PathPoint[]) {
    if (path.length < 2) return;
    for (let i = 0; i < path.length - 1; i++) {
      const start = path[i];
      const end = path[i + 1];
      const length = Math.hypot(end.x - start.x, end.y - start.y);
      this.segments.push({ start, end, length });
      this.totalLength += length;
    }
  }

  getTotalLength(): number {
    return this.totalLength;
  }

  getPositionAtProgress(progress: number): PathPoint | null {
    if (this.segments.length === 0) return null;
    if (progress >= this.totalLength) return null;

    let traveled = 0;
    for (const seg of this.segments) {
      if (traveled + seg.length >= progress) {
        const t = (progress - traveled) / seg.length;
        return {
          x: seg.start.x + (seg.end.x - seg.start.x) * t,
          y: seg.start.y + (seg.end.y - seg.start.y) * t,
        };
      }
      traveled += seg.length;
    }
    const last = this.segments[this.segments.length - 1];
    return { x: last.end.x, y: last.end.y };
  }

  getPositionAtIndex(index: number): PathPoint | null {
    let traveled = 0;
    for (const seg of this.segments) {
      if (traveled + seg.length >= index) {
        const t = (index - traveled) / seg.length;
        return {
          x: seg.start.x + (seg.end.x - seg.start.x) * t,
          y: seg.start.y + (seg.end.y - seg.start.y) * t,
        };
      }
      traveled += seg.length;
    }
    return null;
  }

  getSegmentCount(): number {
    return this.segments.length;
  }
}
