if status is-interactive
    # Commands to run in interactive sessions can go here

    fish_add_path -m ~/.local/bin
    set -x GEM_HOME ~/.gems
    fish_add_path -m ~/.gems/bin

    starship init fish | source
end
