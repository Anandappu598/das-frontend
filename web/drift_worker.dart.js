// Drift worker stub for web - using in-browser mode
// This file is required by drift_flutter but the actual implementation
// uses WebAssembly directly in the main thread when this file is minimal
self.onmessage = function(e) {
  console.log('Drift worker message received');
};
