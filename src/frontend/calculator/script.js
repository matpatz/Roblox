(function(){
  const display = document.getElementById('display');
  const history = document.getElementById('history');
  const screen = document.getElementById('screen');
  const pasteFlash = document.getElementById('pasteFlash');
  const keys = document.getElementById('keys');

  let current = '0';
  let previous = null;
  let operator = null;
  let overwrite = true; // next digit entry replaces display
  let justEvaluated = false;

  const MAX_LEN = 16;

  function formatNumber(numStr){
    if (numStr === 'Error') return numStr;
    // Preserve trailing decimal point / zeros while typing
    if (numStr.includes('.')) {
      const [intPart, decPart] = numStr.split('.');
      const intFormatted = intPart === '' || intPart === '-' ? intPart : Number(intPart).toLocaleString('en-US');
      return (intFormatted || '0') + '.' + decPart;
    }
    if (numStr === '-' || numStr === '') return numStr;
    return Number(numStr).toLocaleString('en-US');
  }

  function render(){
    display.textContent = formatNumber(current);
    if (operator && previous !== null){
      history.textContent = `${formatNumber(previous)} ${opSymbol(operator)}`;
    } else if (justEvaluated && previous !== null) {
      history.textContent = `${formatNumber(previous)} ${opSymbol(operator)} ${formatNumber(lastOperand)} =`;
    } else {
      history.textContent = '\u00A0';
    }
  }

  function opSymbol(op){
    return { add:'+', subtract:'−', multiply:'×', divide:'÷' }[op] || '';
  }

  let lastOperand = null;

  function inputDigit(d){
    if (current === 'Error') { current = '0'; }
    if (justEvaluated){
      current = '0';
      previous = null;
      operator = null;
      justEvaluated = false;
      overwrite = true;
    }
    if (overwrite){
      current = (d === '.') ? '0.' : d;
      overwrite = false;
      return;
    }
    if (d === '.'){
      if (!current.includes('.')) current += '.';
      return;
    }
    if (current === '0') current = d;
    else if (current.replace(/[-.]/g,'').length < MAX_LEN) current += d;
  }

  function setOperator(op){
    if (current === 'Error') return;
    if (operator && !overwrite){
      compute();
    }
    previous = current;
    operator = op;
    overwrite = true;
    justEvaluated = false;
  }

  function compute(){
    if (operator === null || previous === null) return;
    const a = parseFloat(previous);
    const b = parseFloat(current);
    let result;
    switch(operator){
      case 'add': result = a + b; break;
      case 'subtract': result = a - b; break;
      case 'multiply': result = a * b; break;
      case 'divide':
        result = b === 0 ? NaN : a / b;
        break;
    }
    lastOperand = current;
    if (isNaN(result) || !isFinite(result)){
      current = 'Error';
      previous = null;
      operator = null;
    } else {
      // round to avoid float noise, cap length
      result = Math.round((result + Number.EPSILON) * 1e10) / 1e10;
      current = String(result);
      if (current.replace(/[-.]/g,'').length > MAX_LEN){
        current = result.toPrecision(10).replace(/\.?0+$/,'');
      }
    }
    overwrite = true;
  }

  function equals(){
    if (operator === null || previous === null){
      justEvaluated = false;
      return;
    }
    compute();
    justEvaluated = true;
  }

  function clearAll(){
    current = '0';
    previous = null;
    operator = null;
    overwrite = true;
    justEvaluated = false;
  }

  function backspace(){
    if (current === 'Error' || overwrite){ current = '0'; overwrite = true; return; }
    if (current.length <= 1 || (current.length === 2 && current[0] === '-')){
      current = '0';
      overwrite = true;
    } else {
      current = current.slice(0, -1);
    }
  }

  function percent(){
    if (current === 'Error') return;
    current = String(parseFloat(current) / 100);
    overwrite = false;
  }

  function pressVisual(el){
    if (!el) return;
    el.classList.add('pressed');
    setTimeout(() => el.classList.remove('pressed'), 110);
  }

  function handleAction(action, el){
    switch(action){
      case 'clear': clearAll(); break;
      case 'backspace': backspace(); break;
      case 'percent': percent(); break;
      case 'add': case 'subtract': case 'multiply': case 'divide':
        setOperator(action); break;
      case 'decimal': inputDigit('.'); break;
      case 'equals': equals(); break;
    }
    pressVisual(el);
    render();
  }

  keys.addEventListener('click', (e) => {
    const btn = e.target.closest('button.key');
    if (!btn) return;
    if (btn.dataset.digit !== undefined){
      inputDigit(btn.dataset.digit);
      pressVisual(btn);
      render();
    } else if (btn.dataset.action){
      handleAction(btn.dataset.action, btn);
    }
  });

  // Keyboard support
  const keyMap = {
    '+': 'add', '-': 'subtract', '*': 'multiply', 'x': 'multiply', '/': 'divide',
    'Enter': 'equals', '=': 'equals', 'Backspace': 'backspace',
    'Escape': 'clear', 'c': 'clear', 'C': 'clear', '%': 'percent', '.': 'decimal', ',': 'decimal'
  };

  function findButtonFor(action, digit){
    if (digit !== undefined) return keys.querySelector(`[data-digit="${digit}"]`);
    return keys.querySelector(`[data-action="${action}"]`);
  }

  window.addEventListener('keydown', (e) => {
    if (e.metaKey || e.ctrlKey) return; // let paste / shortcuts through
    if (/^[0-9]$/.test(e.key)){
      inputDigit(e.key);
      pressVisual(findButtonFor(undefined, e.key));
      render();
      e.preventDefault();
      return;
    }
    const action = keyMap[e.key];
    if (action){
      handleAction(action, findButtonFor(action));
      e.preventDefault();
    }
  });

  // Clipboard paste support — works anywhere on the page
  window.addEventListener('paste', (e) => {
    const text = (e.clipboardData || window.clipboardData).getData('text');
    if (!text) return;
    const cleaned = text.trim().replace(/,/g, '');
    const match = cleaned.match(/-?\d+(\.\d+)?/);
    if (!match) return;
    e.preventDefault();
    current = match[0];
    // normalize
    if (current.length > 1 && current[0] === '0' && current[1] !== '.') {
      current = String(parseFloat(current));
    }
    overwrite = false;
    justEvaluated = false;
    render();
    pasteFlash.classList.add('show');
    setTimeout(() => pasteFlash.classList.remove('show'), 900);
  });

  render();
})();
