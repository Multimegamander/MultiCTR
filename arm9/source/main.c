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
