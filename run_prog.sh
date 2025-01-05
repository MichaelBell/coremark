mpremote a0 + mount . + exec "os.chdir('/'); import run_tinyqv; run_tinyqv.execute('/remote/$1')"
