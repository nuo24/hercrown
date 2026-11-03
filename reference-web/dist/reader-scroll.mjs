export function indexFromPosition(y, top, height, count) {
  if (count <= 1 || height <= 0) return 0;
  return Math.min(count - 1, Math.max(0, Math.floor((y - top) / height * count)));
}
export function nearestVerse(offsets, scrollTop) {
  if (!offsets.length) return 0;
  let nearest = 0;
  for (let i = 1; i < offsets.length; i++) {
    if (Math.abs(offsets[i] - scrollTop) < Math.abs(offsets[nearest] - scrollTop)) nearest = i;
  }
  return nearest;
}
export function dockScale(distance) {
  return 1 + 0.8 * Math.exp(-0.5 * Math.pow(Math.abs(distance) / 1.1, 2));
}
export function railLayout(height,count){
  const h=Math.max(0,Number.isFinite(height)?height:0),n=Math.max(1,Math.floor(count)||1);
  const gap=n===1?0:Math.min(5,h/(n*4));
  return {gap,segmentHeight:Math.max(0,(h-gap*(n-1))/n)};
}
