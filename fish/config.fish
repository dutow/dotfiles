if status is-interactive
    # Commands to run in interactive sessions can go here

    fish_add_path -m ~/.local/bin

    starship init fish | source
end
