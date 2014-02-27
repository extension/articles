
(function() {
var f = document.getElementById('searchbox_002594610894210374936:hggphannnzi');
if (f && f.q) {
var q = f.q;
var n = navigator;
var l = location;
if (n.platform == 'Win32') {
q.style.cssText = 'border: 1px solid #7e9db9; padding: 2px;';
}
var b = function() {
if (q.value == '') {
q.style.background = '#FFFFFF url(/assets/interface/google_custom_search_watermark.gif) left no-repeat';
}
};
var f = function() {
q.style.background = '#ffffff';
};
q.onfocus = f;
q.onblur = b;
if (!/[&?]q=[^&]/.test(l.search)) {
b();
}
}
})();
