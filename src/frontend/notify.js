(function () {
  let container = null;

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

  function notify(type, message, time) {
    const box = ensure();
    const el = document.createElement('div');
    el.className = 'notify-item ' + (type || '');
    el.textContent = message;
    box.appendChild(el);
    requestAnimationFrame(function () {
      el.classList.add('show');
    });
    if (time !== 0) {
      setTimeout(function () {
        close(el);
      }, typeof time === 'number' ? time * 1000 : 4000);
    }
    return el;
  }

  notify.close = close;

  window.notify = notify;
})();
