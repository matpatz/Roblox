(function () {
  var container = null;

  function ensure() {
    if (!container) {
      container = document.createElement('div');
      container.id = 'notify';
      document.body.appendChild(container);
    }
    return container;
  }

  function close(el) {
    if (!el || !el.parentNode) return;
    el.classList.add('hide');
    setTimeout(function () {
      if (el.parentNode) el.parentNode.removeChild(el);
    }, 250);
  }

  function notify(type, message, duration) {
    var box = ensure();
    var el = document.createElement('div');
    el.className = 'notify-item ' + (type || '');
    el.textContent = message;
    box.appendChild(el);
    requestAnimationFrame(function () {
      el.classList.add('show');
    });
    if (duration !== 0) {
      setTimeout(function () {
        close(el);
      }, typeof duration === 'number' ? duration : 4000);
    }
    return el;
  }

  notify.close = close;

  window.notify = notify;
})();
