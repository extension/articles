(function() {
   var s = document.getElementById('search');
   if (s && s.q) {
      var q = s.q;
      var n = navigator;
      var l = location;
      if (n.platform == 'Win32') {
         q.style.cssText = 'border: 1px solid #7e9db9; padding: 2px;';
      }
      var b = function() {
         if (q.value == '') {
            q.style.background = '#FFFFFF url(/images/search/google_custom_search_watermark.gif) left no-repeat';
         }
      };
      var f = function() {
         q.style.background = '#ffffff';
      };
      var g = function() {
         s.submit();
      }
      q.onfocus = f;
      q.onblur = b;
      if (!/[&?]q=[^&]/.test(l.search)) {
         b();
      } else if (!/[&?]cx=[^&]/.test(l.search)) {
         g();
      }
   }
})();
