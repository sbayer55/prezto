#!/opt/homebrew/bin/fish

function kill-logi
    ps -A | grep -i 'Logitech' | grep -v 'grep' | awk '{ print $1 }' | sudo xargs kill -9
end
