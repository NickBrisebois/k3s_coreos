### Install File Templates

These files get rendered and injected into the final CoreOS butane config. 

Note: Scripts in scripts/ require double curly braces to avoid Python's template string formatting thinking they're variables.

Maybe i'll replace `.format()` with an actual template library...
