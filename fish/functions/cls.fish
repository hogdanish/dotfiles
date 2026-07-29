function cls --description 'clear the screen and drop the scrollback'
    # `clear` alone only scrolls the viewport; \e[3J is the erase-saved-lines sequence that
    # actually discards scrollback, which is the thing you wanted when you typed this.
    clear; and printf '\e[3J'
end
