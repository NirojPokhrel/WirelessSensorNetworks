module ShellDemoP {
	uses {
		interface Boot;
		interface SplitControl as RadioControl;

		interface ShellCommand as DemoCmd;
	}
} implementation {

	event void Boot.booted() {
		call RadioControl.start();
	}

	event char* DemoCmd.eval(int argc, char* argv[]) {
		char* reply_buf = call DemoCmd.getBuffer(32);
		strcpy(reply_buf, "Hello World!\n");
		return reply_buf;
	}

	event void RadioControl.startDone(error_t e) {}
	event void RadioControl.stopDone(error_t e) {}
}
