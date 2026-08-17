if status is-interactive
    figlet "Hello Adheesh"

    # Starship custom prompt
    starship init fish | source
end
