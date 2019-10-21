void version_info()
{
    int pos_y = draw_loading("Version info", "MultiCTR version " VERSION) + SPACING_VERT;
    int version_pos_x = SPACING_HORIZ * 21;

    draw_string(screen_top_left, "NATIVE_FIRM version:", 0, pos_y, COLOR_NEUTRAL);
    draw_string(screen_top_left, current_firm->version_string, version_pos_x, pos_y, COLOR_NEUTRAL);

    if (current_twl_firm) {
        pos_y += SPACING_VERT;

        draw_string(screen_top_left, "TWL_FIRM version:", 0, pos_y, COLOR_NEUTRAL);
        draw_string(screen_top_left, current_twl_firm->version_string, version_pos_x, pos_y, COLOR_NEUTRAL);
    }

    if (current_agb_firm) {
        pos_y += SPACING_VERT;

        draw_string(screen_top_left, "AGB_FIRM version:", 0, pos_y, COLOR_NEUTRAL);
        draw_string(screen_top_left, current_agb_firm->version_string, version_pos_x, pos_y, COLOR_NEUTRAL);
    }

    draw_string(screen_top_left, "Press B to return", 0, pos_y + 20, COLOR_SELECTED);
    while (1) {
        uint16_t key = wait_key();

        if (key == (key_released | key_b)) {
            return;
        }
    }
}


void menu_main(){
  while (1) {
    char *options[] = {"Boot CFW",
                       "Chainloader",
                       "More options...",
                       "Version info",
                       "Power off"};
    int result = draw_menu("MultiCTR " VERSION, 0, sizeof(options) / sizeof(char *), options);

    switch (result) {
        case 0:
            save_config();
            boot_cfw();
            break;
        case 1:
            menu_chainloader();
            break;
        case 2:
            menu_more();
            break;
        case 3:
            version_info();
            break;
        case 4:
            i2cWriteRegister(I2C_DEV_MCU, 0x20, 1);
            while(1);  // Won't break out of this one >:D
}
