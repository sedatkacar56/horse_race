function autoFitLanes() {
  totalLanes = TOTAL_LANES;                                   // fixed
  laneGap = (canvas.height - 2 * laneOffset) / totalLanes;    // fit 5 in view
  horses.forEach(h => {
    const baseY = laneOffset + (h.lane - 1) * laneGap;
    h.yBase = baseY;                     // base center of lane
    h.yDrift = h.yDrift || 0;            // side drift inside lane
    h.passDir = h.passDir || 0;          // -1 up, +1 down
    h.passTimer = h.passTimer || 0;
    h.y = baseY + h.yDrift;              // actual draw y
  });
}