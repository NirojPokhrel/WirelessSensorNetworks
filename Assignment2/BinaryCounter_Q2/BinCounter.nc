interface BinCounter {
	command void start();
	command void stop();
	event void completed();
}