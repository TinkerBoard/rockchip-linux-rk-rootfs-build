/*Tinker-Power-Management Version 1.01*/

#include <ncurses.h>
#include <locale.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>

#define SQA_HEIGHT 21
#define SQC_HEIGHT 19
#define SQ_WIDTH (COLS/9)
#define LEFT (COLS%9)

#define A_EXTEND 3
#define SUB_SHIFT_R 4
#define SUBB_SHIFT_D 5
#define SUBC_SHIFT_D 4

#define MAX_CPU_SQ 4
#define MAX_A53_FREQ 6
#define MAX_A72_FREQ 8

#define SQFORM_WIDTH ((SQ_WIDTH * 5 + LEFT - A_EXTEND - 3) / 5)

WINDOW *BOARDA;
WINDOW *BOARDB;
WINDOW *BOARDC;

WINDOW *FORMA[9];
WINDOW *FORMB[6];
WINDOW *FORMC[9];
WINDOW *FORMD[6];

WINDOW *CPUGOVER[4];
WINDOW *A53FREQ[6];
WINDOW *A72FREQ[8];

FILE *fp;
char buffer[50];
int curr_menu = 0, mode = 0;
int curr_governor, dirty;
int switch_tag, curr_tag;

int a53_min, a53_max, a72_min, a72_max;

int kbhit(void)
{
	struct termios oldt, newt;
	int ch;
	int oldf;
	tcgetattr(STDIN_FILENO, &oldt);
	newt = oldt;
	newt.c_lflag &= ~(ICANON | ECHO);
	tcsetattr(STDIN_FILENO, TCSANOW, &newt);
	oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
	fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
	ch = getchar();
	tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
	fcntl(STDIN_FILENO, F_SETFL, oldf);
	if(ch != EOF) {
		ungetc(ch, stdin);
		return 1;
	}
	return 0;
}

void draw_square_A(void) {
	mvwprintw(BOARDA, 1, 2, "Device Info");

	fp = popen("cat /proc/boardinfo", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 3, 3,"Name\t\t= %s", buffer);

	fp = popen("cat /proc/boardver", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 4, 3,"Version\t= %s", buffer);

	fp = popen("cat /proc/device-tree/serial-number", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 5, 3,"SN/PPID\t= %s", buffer);

	mvwprintw(BOARDA, 7, 3,"SoC/CPU\t= RK3399PRO");

	//yun
	fp = popen("cat /proc/meminfo | grep 'MemTotal:' | rev | cut -d ' ' -f2 | rev", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 8, 3,"Memory\t= %dGB", atoi(buffer) / 1000000 + 1);

	fp = popen("lsblk | grep -w 'mmcblk1'; echo $?", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	if (atoi(buffer) == 0) {
		fp = popen("lsblk | grep -w 'mmcblk1' | grep 'disk' | rev | cut -d ' ' -f5 | rev", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);
		mvwprintw(BOARDA, 9, 3,"Storage\t= eMMC(mmcblk1)\t\t%s", buffer);
	} else
		mvwprintw(BOARDA, 9, 3,"Storage\t= No eMMC(mmcblk1)");

	fp = popen("lsblk | grep -w 'mmcblk0'; echo $?", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	if (atoi(buffer) == 0) {
		fp = popen("lsblk | grep -w 'mmcblk0' | grep 'disk' | rev | cut -d ' ' -f5 | rev", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);
		mvwprintw(BOARDA, 10, 3,"\t\t  SD card(mmcblk0)\t%s", buffer);
	} else
		mvwprintw(BOARDA, 10, 3,"\t\t  No SD card(mmcblk0)\t     ");

	fp = popen("cat /etc/os-release | grep -w 'NAME=' | cut -d '\"' -f2", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 12, 3,"OS\t\t= %s", buffer);

	fp = popen("cat /etc/os-release | grep 'VERSION=' | cut -d '\"' -f2", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 13, 3,"Version\t= %s", buffer);

	fp = popen("lscpu | grep 'Architecture' | rev | cut -d ' ' -f1 | rev", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 14, 3,"Platform\t= %s", buffer);

	fp = popen("cat /etc/version", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 16, 3,"Build\t= %s", buffer);

	mvwprintw(BOARDA, 17, 3,"Kernel:");

	fp = popen("cat /proc/version | awk {print'$1\" \"$2\" \"$3'}", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 18, 5,"Release\t= %s", buffer);

	fp = popen("cat /proc/version | awk {print'$13\" \"$14\" \"$15\" \"$16\" \"$17\" \"$18\" \"$19\" \"$20'}", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDA, 19, 5,"Version\t= %s", buffer);

	box(BOARDA, 0, 0);
}

void draw_square_B(int mode) {
	mvwprintw(BOARDB, 1, 2, "System Config");
	mvwprintw(BOARDB, 3, 3,"CPU:");

	mvwprintw(BOARDB, 4, 5,"Governor\t= ");

	fp = popen("cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);

	if (a53_min == 408 && a72_min == 408 && a53_max == 1416 && a72_max == 1800)
		dirty = 0;
	else
		dirty = 1;

	if (!strncmp(buffer, "ondemand", strlen("ondemand"))) {
		if (curr_menu)
			curr_governor = 1;
		else if (dirty == 0)
			curr_governor = 0;
		else {
			curr_governor = 1;
			curr_menu = 1;
		}
	} else if (!strncmp(buffer, "powersave", strlen("powersave")))
		curr_governor = 2;
	else if (!strncmp(buffer, "performance", strlen("performance")))
		curr_governor = 3;

	if (mode == 1)
		mvwprintw(BOARDB, 4, 18,"            ");
	else {
		wattron(BOARDB, A_BOLD);

		switch(curr_governor) {
			case 0:
				mvwprintw(BOARDB, 4, 18,"auto");
				break;
			case 1:
				mvwprintw(BOARDB, 4, 18,"manual");
				break;
			default:
				mvwprintw(BOARDB, 4, 18,"%s", buffer);
		}

		wattroff(BOARDB, A_BOLD);
	}

	mvwprintw(BOARDB, 13, 3,"GPU:");

	box(BOARDB, 0, 0);
}

void draw_square_C(void) {
	mvwprintw(BOARDC, 1, 2,"Monitor");
	mvwprintw(BOARDC, 3, 3,"CPU:");
	mvwprintw(BOARDC, 12, 3,"GPU:");

	mvwprintw(BOARDC, 3, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2, "CPU usage:");
	mvwprintw(BOARDC, 5, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2, "[");
	mvwprintw(BOARDC, 5, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + 51, "]");

	mvwprintw(BOARDC, 7, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2, "GPU usage:");
	mvwprintw(BOARDC, 9, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2, "[");
	mvwprintw(BOARDC, 9, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + 51, "]");

	mvwprintw(BOARDC, 11, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2, "Memory usage:");
	mvwprintw(BOARDC, 13, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2, "[");
	mvwprintw(BOARDC, 13, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + 51, "]");

	box(BOARDC, 0, 0);
}

void draw_square_FORMAC(int sq) {
	if (sq == 0) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_ULCORNER, ACS_TTEE, ACS_LTEE, ACS_PLUS);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_ULCORNER, ACS_TTEE, ACS_LTEE, ACS_PLUS);
	} else if (sq == 7) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_LTEE, ACS_PLUS, ACS_LTEE, ACS_PLUS);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_LTEE, ACS_PLUS, ACS_LTEE, ACS_PLUS);

		fp = popen("cat /proc/cpuinfo | grep 'CPU part' | grep -c '0xd03'", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);
		mvwprintw(FORMA[sq], 1, 2,"%d x Arm Cortex-A53", atoi(buffer));
		mvwprintw(FORMC[sq], 1, 2,"%d x Arm Cortex-A53", atoi(buffer));
	} else if (sq == 8) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_LTEE, ACS_PLUS, ACS_LLCORNER, ACS_BTEE);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_LTEE, ACS_PLUS, ACS_LLCORNER, ACS_BTEE);

		fp = popen("cat /proc/cpuinfo | grep 'CPU part' | grep -c '0xd08'", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);
		mvwprintw(FORMA[sq], 1, 2,"%d x Arm Cortex-A72", atoi(buffer));
		mvwprintw(FORMC[sq], 1, 2,"%d x Arm Cortex-A72", atoi(buffer));
	} else if (sq == 5) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_TTEE, ACS_TTEE, ACS_PLUS, ACS_PLUS);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_TTEE, ACS_TTEE, ACS_PLUS, ACS_PLUS);

		mvwprintw(FORMA[sq], 1, (SQFORM_WIDTH - 10) / 2,"Min. freq.");
		mvwprintw(FORMC[sq], 1, (SQFORM_WIDTH + 1 - 11) / 2,"Curr. freq.");
	} else if (sq == 1) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_PLUS, ACS_PLUS, ACS_PLUS);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_PLUS, ACS_PLUS, ACS_PLUS);

		fp = popen("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);

		a53_min = atoi(buffer) / 1000;
		mvwprintw(FORMA[sq], 1, (SQFORM_WIDTH - 3) / 2,"%d ", a53_min);

		switch (a53_min) {
			case 408:
				curr_tag = 0;
				break;
			case 600:
				curr_tag = 1;
				break;
			case 816:
				curr_tag = 2;
				break;
			case 1008:
				curr_tag = 3;
				break;
			case 1200:
				curr_tag = 4;
				break;
			case 1416:
				curr_tag = 5;
				break;
		}
	} else if (sq == 2) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_PLUS, ACS_BTEE, ACS_BTEE);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_PLUS, ACS_BTEE, ACS_BTEE);

		fp = popen("cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);

		a72_min = atoi(buffer) / 1000;
		mvwprintw(FORMA[sq], 1, (SQFORM_WIDTH - 3) / 2,"%d ", a72_min);

		switch (a72_min) {
			case 408:
				curr_tag = 0;
				break;
			case 600:
				curr_tag = 1;
				break;
			case 816:
				curr_tag = 2;
				break;
			case 1008:
				curr_tag = 3;
				break;
			case 1200:
				curr_tag = 4;
				break;
			case 1416:
				curr_tag = 5;
				break;
			case 1608:
				curr_tag = 6;
				break;
			case 1800:
				curr_tag = 7;
				break;
                }
	} else if (sq == 6) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_TTEE, ACS_URCORNER, ACS_PLUS, ACS_RTEE);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_TTEE, ACS_URCORNER, ACS_PLUS, ACS_RTEE);

		mvwprintw(FORMA[sq], 1, (SQFORM_WIDTH - 10) / 2,"Max. freq.");
		mvwprintw(FORMC[sq], 1, (SQFORM_WIDTH + 1 - 11) / 2,"Temperature");
	} else if (sq == 3) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_RTEE, ACS_PLUS, ACS_RTEE);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_RTEE, ACS_PLUS, ACS_RTEE);

		fp = popen("cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);

		a53_max = atoi(buffer) / 1000;
		mvwprintw(FORMA[sq], 1, (SQFORM_WIDTH - 4) / 2,"%d ", a53_max);

		switch (a53_max) {
			case 408:
				curr_tag = 0;
				break;
			case 600:
				curr_tag = 1;
				break;
			case 816:
				curr_tag = 2;
				break;
			case 1008:
				curr_tag = 3;
				break;
			case 1200:
				curr_tag = 4;
				break;
			case 1416:
				curr_tag = 5;
				break;
                }
	} else if (sq == 4) {
		wborder(FORMA[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_RTEE, ACS_BTEE, ACS_LRCORNER);
		wborder(FORMC[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_RTEE, ACS_BTEE, ACS_LRCORNER);

		fp = popen("cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);

		a72_max = atoi(buffer) / 1000;
		mvwprintw(FORMA[sq], 1, (SQFORM_WIDTH - 4) / 2,"%d ", a72_max);

		switch (a72_max) {
			case 408:
				curr_tag = 0;
				break;
			case 600:
				curr_tag = 1;
				break;
			case 816:
				curr_tag = 2;
				break;
			case 1008:
				curr_tag = 3;
				break;
			case 1200:
				curr_tag = 4;
				break;
			case 1416:
				curr_tag = 5;
				break;
			case 1608:
				curr_tag = 6;
				break;
			case 1800:
				curr_tag = 7;
				break;
                }
	}
}

void draw_square_FORMBD(int sq) {
	if (sq == 0) {
		wborder(FORMB[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_ULCORNER, ACS_TTEE, ACS_LTEE, ACS_PLUS);
		wborder(FORMD[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_ULCORNER, ACS_TTEE, ACS_LTEE, ACS_PLUS);
	} else if (sq == 5) {
		wborder(FORMB[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_LTEE, ACS_PLUS, ACS_LLCORNER, ACS_BTEE);
		wborder(FORMD[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_LTEE, ACS_PLUS, ACS_LLCORNER, ACS_BTEE);

		fp = popen("cat /sys/class/devfreq/ff9a0000.gpu/device/gpuinfo | cut -d ' ' -f1", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);

		mvwprintw(FORMB[sq], 1, 2,"Arm %s", buffer);
		mvwprintw(FORMD[sq], 1, 2,"Arm %s", buffer);
	} else if (sq == 3) {
		wborder(FORMB[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_TTEE, ACS_TTEE, ACS_PLUS, ACS_PLUS);
		wborder(FORMD[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_TTEE, ACS_TTEE, ACS_PLUS, ACS_PLUS);

		mvwprintw(FORMB[sq], 1, (SQFORM_WIDTH - 10) / 2,"Min. freq.");
		mvwprintw(FORMD[sq], 1, (SQFORM_WIDTH + 1 - 11) / 2,"Curr. freq.");
	} else if (sq == 1) {
		wborder(FORMB[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_PLUS, ACS_BTEE, ACS_BTEE);
		wborder(FORMD[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_PLUS, ACS_BTEE, ACS_BTEE);

		fp = popen("cat /sys/class/devfreq/ff9a0000.gpu/min_freq", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);

		mvwprintw(FORMB[sq], 1, (SQFORM_WIDTH - 3) / 2,"%d", atoi(buffer) / 1000000);
	} else if (sq == 4) {
		wborder(FORMB[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_TTEE, ACS_URCORNER, ACS_PLUS, ACS_RTEE);
		wborder(FORMD[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_TTEE, ACS_URCORNER, ACS_PLUS, ACS_RTEE);

		mvwprintw(FORMB[sq], 1, (SQFORM_WIDTH - 10) / 2,"Max. freq.");
		mvwprintw(FORMD[sq], 1, (SQFORM_WIDTH + 1 - 11) / 2,"Temperature");
	} else if (sq == 2) {
		wborder(FORMB[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_RTEE, ACS_BTEE, ACS_LRCORNER);
		wborder(FORMD[sq], ACS_VLINE, ACS_VLINE, ACS_HLINE, ACS_HLINE, ACS_PLUS, ACS_RTEE, ACS_BTEE, ACS_LRCORNER);

		fp = popen("cat /sys/class/devfreq/ff9a0000.gpu/max_freq", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);

		mvwprintw(FORMB[sq], 1, (SQFORM_WIDTH - 3) / 2,"%d", atoi(buffer) / 1000000);
	}
}

void draw_square_CPUGOVER(int sq, int mode) {
	if (sq == 0) {
		if (mode)
			mvwprintw(CPUGOVER[sq], 1, 1, "auto");
		else
			mvwprintw(CPUGOVER[sq], 1, 1, "    ");
	} else if (sq == 1) {
		if (mode)
			mvwprintw(CPUGOVER[sq], 1, 1, "manual");
		else
			mvwprintw(CPUGOVER[sq], 1, 1, "      ");
	} else if (sq == 2) {
		if (mode)
			mvwprintw(CPUGOVER[sq], 1, 1, "powersave");
		else
			mvwprintw(CPUGOVER[sq], 1, 1, "         ");
	} else if (sq == 3) {
		if (mode)
			mvwprintw(CPUGOVER[sq], 1, 1, "performance");
		else
			mvwprintw(CPUGOVER[sq], 1, 1, "           ");
	}
}

void draw_square_A53FREQ(int sq, int mode) {
	if (sq == 0) {
		if (mode)
			mvwprintw(A53FREQ[sq], 1, 1, "408");
		else
			mvwprintw(A53FREQ[sq], 1, 1, "   ");
	} else if (sq == 1) {
		if (mode)
			mvwprintw(A53FREQ[sq], 1, 1, "600");
		else
			mvwprintw(A53FREQ[sq], 1, 1, "   ");
	} else if (sq == 2) {
		if (mode)
			mvwprintw(A53FREQ[sq], 1, 1, "816");
		else
			mvwprintw(A53FREQ[sq], 1, 1, "   ");
	} else if (sq == 3) {
		if (mode)
			mvwprintw(A53FREQ[sq], 1, 1, "1008");
		else
			mvwprintw(A53FREQ[sq], 1, 1, "    ");
	} else if (sq == 4) {
		if (mode)
			mvwprintw(A53FREQ[sq], 1, 1, "1200");
		else
			mvwprintw(A53FREQ[sq], 1, 1, "    ");
	} else if (sq == 5) {
		if (mode)
			mvwprintw(A53FREQ[sq], 1, 1, "1416");
		else
			mvwprintw(A53FREQ[sq], 1, 1, "    ");
	}
}

void draw_square_A72FREQ(int sq, int mode) {
	if (sq == 0) {
		if (mode)
			mvwprintw(A72FREQ[sq], 1, 1, "408");
		else
			mvwprintw(A72FREQ[sq], 1, 1, "   ");
	} else if (sq == 1) {
		if (mode)
			mvwprintw(A72FREQ[sq], 1, 1, "600");
		else
			mvwprintw(A72FREQ[sq], 1, 1, "   ");
	} else if (sq == 2) {
		if (mode)
			mvwprintw(A72FREQ[sq], 1, 1, "816");
		else
			mvwprintw(A72FREQ[sq], 1, 1, "   ");
	} else if (sq == 3) {
		if (mode)
			mvwprintw(A72FREQ[sq], 1, 1, "1008");
		else
			mvwprintw(A72FREQ[sq], 1, 1, "    ");
	} else if (sq == 4) {
		if (mode)
			mvwprintw(A72FREQ[sq], 1, 1, "1200");
		else
			mvwprintw(A72FREQ[sq], 1, 1, "    ");
	} else if (sq == 5) {
		if (mode)
			mvwprintw(A72FREQ[sq], 1, 1, "1416");
		else
			mvwprintw(A72FREQ[sq], 1, 1, "    ");
	} else if (sq == 6) {
		if (mode)
			mvwprintw(A72FREQ[sq], 1, 1, "1608");
		else
			mvwprintw(A72FREQ[sq], 1, 1, "    ");
	} else if (sq == 7) {
		if (mode)
			mvwprintw(A72FREQ[sq], 1, 1, "1800");
		else
			mvwprintw(A72FREQ[sq], 1, 1, "    ");
	}
}

void highlight_a53_freq(int sq) {
	wattron(A53FREQ[sq], A_BOLD);
	draw_square_A53FREQ(sq, mode);
	wattroff(A53FREQ[sq], A_BOLD);
}

void highlight_a72_freq(int sq) {
        wattron(A72FREQ[sq], A_BOLD);
        draw_square_A72FREQ(sq, mode);
        wattroff(A72FREQ[sq], A_BOLD);
}

void highlight_square(int sq) {
	wattron(CPUGOVER[sq], A_BOLD);
	draw_square_CPUGOVER(sq, mode);
	wattroff(CPUGOVER[sq], A_BOLD);
}

void highlight_menu(int menu) {
	if (menu) {
		wattron(FORMA[menu], A_BOLD);
		draw_square_FORMAC(menu);
		wattroff(FORMA[menu], A_BOLD);
	}
}

void create_board(void) {
	int i;
	int startx = 0, starty = 0;

	BOARDA = newwin(SQA_HEIGHT, SQ_WIDTH * 4 + A_EXTEND, starty, startx);
	BOARDB = newwin(SQA_HEIGHT, SQ_WIDTH * 5 + LEFT - A_EXTEND, starty, startx + SQ_WIDTH * 4 + A_EXTEND);
	BOARDC = newwin(SQC_HEIGHT, COLS, starty + SQA_HEIGHT, startx);

	FORMA[0] = derwin(BOARDB, 3, SQFORM_WIDTH * 3, SUBB_SHIFT_D, SUB_SHIFT_R);
	FORMA[7] = derwin(BOARDB, 3, SQFORM_WIDTH * 3, SUBB_SHIFT_D + 2, SUB_SHIFT_R);
	FORMA[8] = derwin(BOARDB, 3, SQFORM_WIDTH * 3, SUBB_SHIFT_D + 4, SUB_SHIFT_R);
	FORMA[5] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMA[1] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D + 2, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMA[2] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D + 4, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMA[6] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D, SUB_SHIFT_R + SQFORM_WIDTH * 4 - 2);
	FORMA[3] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D + 2, SUB_SHIFT_R + SQFORM_WIDTH * 4 - 2);
	FORMA[4] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D + 4, SUB_SHIFT_R + SQFORM_WIDTH * 4 - 2);

	FORMC[0] = derwin(BOARDC, 3, SQFORM_WIDTH * 3, SUBC_SHIFT_D, SUB_SHIFT_R);
	FORMC[7] = derwin(BOARDC, 3, SQFORM_WIDTH * 3, SUBC_SHIFT_D + 2, SUB_SHIFT_R);
	FORMC[8] = derwin(BOARDC, 3, SQFORM_WIDTH * 3, SUBC_SHIFT_D + 4, SUB_SHIFT_R);
	FORMC[5] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMC[1] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D + 2, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMC[2] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D + 4, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMC[6] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D, SUB_SHIFT_R + SQFORM_WIDTH * 4 + 1 - 2);
	FORMC[3] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D + 2, SUB_SHIFT_R + SQFORM_WIDTH * 4 + 1 - 2);
	FORMC[4] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D + 4, SUB_SHIFT_R + SQFORM_WIDTH * 4 + 1 - 2);

	FORMB[0] = derwin(BOARDB, 3, SQFORM_WIDTH * 3, SUBB_SHIFT_D + 9, SUB_SHIFT_R);
	FORMB[5] = derwin(BOARDB, 3, SQFORM_WIDTH * 3, SUBB_SHIFT_D + 9 + 2, SUB_SHIFT_R);
	FORMB[3] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D + 9, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMB[1] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D + 9 + 2, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMB[4] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D + 9, SUB_SHIFT_R + SQFORM_WIDTH * 4 - 2);
	FORMB[2] = derwin(BOARDB, 3, SQFORM_WIDTH, SUBB_SHIFT_D + 9 + 2, SUB_SHIFT_R + SQFORM_WIDTH * 4 - 2);

	FORMD[0] = derwin(BOARDC, 3, SQFORM_WIDTH * 3, SUBC_SHIFT_D + 9, SUB_SHIFT_R);
	FORMD[5] = derwin(BOARDC, 3, SQFORM_WIDTH * 3, SUBC_SHIFT_D + 9 + 2, SUB_SHIFT_R);
	FORMD[3] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D + 9, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMD[1] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D + 9 + 2, SUB_SHIFT_R + SQFORM_WIDTH * 3 - 1);
	FORMD[4] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D + 9, SUB_SHIFT_R + SQFORM_WIDTH * 4 + 1 - 2);
	FORMD[2] = derwin(BOARDC, 3, SQFORM_WIDTH + 1, SUBC_SHIFT_D + 9 + 2, SUB_SHIFT_R + SQFORM_WIDTH * 4 + 1 - 2);

	CPUGOVER[0] = derwin(BOARDB, 3, sizeof(" auto "), SUBB_SHIFT_D - 2, 17);
	CPUGOVER[1] = derwin(BOARDB, 3, sizeof(" manual "), SUBB_SHIFT_D - 2, 17 + sizeof(" auto ") - 1);
	CPUGOVER[2] = derwin(BOARDB, 3, sizeof(" powersave "), SUBB_SHIFT_D - 2, 17 + sizeof(" auto ") + sizeof(" manual ") - 2);
	CPUGOVER[3] = derwin(BOARDB, 3, sizeof(" performance "), SUBB_SHIFT_D - 2, 17 + sizeof(" auto ") + sizeof(" manual ") + sizeof(" powersave ") - 3);

	for (i = 0; i < 6; i++)			// sizeof(" xxxx ")
		A53FREQ[i] = derwin(BOARDB, 3, 6, SUBB_SHIFT_D + 6, SUB_SHIFT_R + i * 6 - i);

	for (i = 0; i < 8; i++)			// sizeof(" xxxx ")
		A72FREQ[i] = derwin(BOARDB, 3, 6, SUBB_SHIFT_D + 6, SUB_SHIFT_R + i * 6 - i);

	draw_square_A();
	draw_square_C();

	for (i = 8; i >= 0; i--)
		draw_square_FORMAC(i);
	for (i = 5; i >= 0; i--)
		draw_square_FORMBD(i);

	draw_square_B(mode);
	highlight_menu(curr_menu);
}

void cpu_info(void) {
	int reg;
	double temp;

	fp = popen("sudo cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(FORMC[1], 1, (SQFORM_WIDTH + 1 - 3) / 2, "%d ", atoi(buffer) / 1000);

	fp = popen("sudo cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(FORMC[2], 1, (SQFORM_WIDTH + 1 - 3) / 2, "%d ", atoi(buffer) / 1000);

	fp = popen("cat /sys/class/thermal/thermal_zone0/temp", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	temp = (float)(atoi(buffer)) / 1000;
	mvwprintw(FORMC[3], 1, (SQFORM_WIDTH + 1 - 7) / 2, "%.2f°C", temp);
	mvwprintw(FORMC[4], 1, (SQFORM_WIDTH + 1 - 7) / 2, "%.2f°C", temp);

	fp = popen("top -b -n2 -d0.1 | grep 'Cpu(s)' | awk '{print $2+$4+$6+$14}' | tail -n1", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDC, 3, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + 11, "%d%%  ", atoi(buffer));

	for (reg = 1; reg <= 50; reg++) {
		if (reg > atoi(buffer) / 2)
			mvwprintw(BOARDC, 5, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + reg, " ");
		else
			mvwprintw(BOARDC, 5, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + reg, "#");
	}
}

void gpu_info(void) {
	int reg;
	double temp;

	fp = popen("cat /sys/class/devfreq/ff9a0000.gpu/cur_freq", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(FORMD[1], 1, (SQFORM_WIDTH + 1 - 3) / 2, "%d ", atoi(buffer) / 1000000);

	fp = popen("cat /sys/class/thermal/thermal_zone1/temp", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	temp = (float)(atoi(buffer)) / 1000;
	mvwprintw(FORMD[2], 1, (SQFORM_WIDTH + 1 - 7) / 2, "%.2f°C", temp);

	fp = popen("cat /sys/devices/platform/ff9a0000.gpu/utilisation", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mvwprintw(BOARDC, 7, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + 11, "%d%%  ", atoi(buffer));

	for (reg = 1; reg <= 50; reg++) {
		if (reg > atoi(buffer) / 2)
			mvwprintw(BOARDC, 9, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + reg, " ");
		else
			mvwprintw(BOARDC, 9, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + reg, "#");
	}
}

void ddr_info(void) {
	int reg;
	int mem_total, mem_used, mem_usage;

	fp = popen("lsblk | grep -w 'mmcblk1'; echo $?", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	if (atoi(buffer) == 0) {
		fp = popen("lsblk | grep -w 'mmcblk1' | grep 'disk' | rev | cut -d ' ' -f5 | rev", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);
		mvwprintw(BOARDA, 9, 10,"\t= eMMC(mmcblk1)\t\t%s", buffer);
	} else
		mvwprintw(BOARDA, 9, 10,"\t= No eMMC(mmcblk1)");

	fp = popen("lsblk | grep -w 'mmcblk0'; echo $?", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	if (atoi(buffer) == 0) {
		fp = popen("lsblk | grep -w 'mmcblk0' | grep 'disk' | rev | cut -d ' ' -f5 | rev", "r");
		memset(buffer, '\0', sizeof(buffer));
		fgets(buffer, sizeof(buffer), fp);
		pclose(fp);
		mvwprintw(BOARDA, 10, 3,"\t\t  SD card(mmcblk0)\t%s", buffer);
	} else
		mvwprintw(BOARDA, 10, 3,"\t\t  No SD card(mmcblk0)\t     ");

	box(BOARDA, 0, 0);

	fp = popen("cat /proc/meminfo | grep 'MemTotal' | rev | cut -d ' ' -f2 | rev", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mem_total = atoi(buffer) / 1000;

	fp = popen("cat /proc/meminfo | grep 'MemAvailable' | rev | cut -d ' ' -f2 | rev", "r");
	memset(buffer, '\0', sizeof(buffer));
	fgets(buffer, sizeof(buffer), fp);
	pclose(fp);
	mem_used = mem_total - atoi(buffer) / 1000;

	mem_usage = mem_used * 100 / mem_total;

	mvwprintw(BOARDC, 11, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + 14, "                     ");	//MAX:21

	mvwprintw(BOARDC, 11, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + 14, "%d / %d MB (%d%%)", mem_used, mem_total, mem_usage);

	for (reg = 1; reg <= 50; reg++) {
		if (reg > mem_usage / 2)
			mvwprintw(BOARDC, 13, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + reg, " ");
		else
			mvwprintw(BOARDC, 13, SQFORM_WIDTH * 5 + SUB_SHIFT_R * 2 + reg, "#");
	}
}

int main() {
	int i;
	char key;

	setlocale(LC_ALL,"");

	initscr();
	noecho();

	create_board();

	refresh();
	for (i = 0; i < 9; i++) {
		wrefresh(FORMA[i]);
		wrefresh(FORMC[i]);
	}
	for (i = 0; i < 6; i++) {
		wrefresh(FORMB[i]);
		wrefresh(FORMD[i]);
	}
	wrefresh(BOARDA);
	wrefresh(BOARDB);
	wrefresh(BOARDC);

	while (1) {
		if (!kbhit()) {
			if (mode == 1) {
				if (LINES > 40)
					mvprintw(LINES - 1, 0, "Press Left or Right keys to select the governor and Space key to save. Press Q to quit and go back.                       ");
				else if (LINES == 40) {
					box(BOARDC, 0, 0);
					mvprintw(LINES - 1, 0, "Press Left or Right keys to select the governor and Space key to save. Press Q to quit and go back.");
					wrefresh(BOARDC);
				}
			} else if (mode == 0) {
				if (curr_governor == 1) {
					if (LINES > 40)
						mvprintw(LINES - 1, 0, "Press C to change governor or Ctrl + C to exit. Use Arrow keys to move to the frequency to change and Space key to select.");
					else if (LINES == 40) {
						box(BOARDC, 0, 0);
						mvprintw(LINES - 1, 0, "Press C to change governor or Ctrl + C to exit. Use Arrow keys to move to the frequency to change and Space key to select.");
						wrefresh(BOARDC);
					}
				} else {
					if (LINES > 40)
						mvprintw(LINES - 1, 0, "Press C to change governor or Ctrl + C to exit.                                                                           ");
					else if (LINES == 40) {
						box(BOARDC, 0, 0);
						mvprintw(LINES - 1, 0, "Press C to change governor or Ctrl + C to exit.");
						wrefresh(BOARDC);
					}
				}
			} else {
				if (LINES > 40)
					mvprintw(LINES - 1, 0, "Press Left or Right keys to select the frequency and Space key to save. Press Q to quit and go back.                      ");
				else if (LINES == 40) {
					box(BOARDC, 0, 0);
					mvprintw(LINES - 1, 0, "Press Left or Right keys to select the frequency and Space key to save. Press Q to quit and go back.");
					wrefresh(BOARDC);
				}
			}

			refresh();

			cpu_info();
			gpu_info();
			ddr_info();
		} else {
			key = getchar();

			if (mode == 1) {
				if (key == ' ') {
					if (switch_tag != 1 && dirty == 1) {
						fp = popen("sudo su -c \"echo 408000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq\"", "r");
						pclose(fp);

						fp = popen("sudo sed -i 's/\\(a53_minfreq=\\).*/\\1408000/g' /boot/config.txt", "r");
						pclose(fp);

						fp = popen("sudo su -c \"echo 1416000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq\"", "r");
						pclose(fp);

						fp = popen("sudo sed -i 's/\\(a53_maxfreq=\\).*/\\11416000/g' /boot/config.txt", "r");
						pclose(fp);

						fp = popen("sudo su -c \"echo 408000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
						pclose(fp);

						fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\1408000/g' /boot/config.txt", "r");
						pclose(fp);

						fp = popen("sudo su -c \"echo 1800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
						pclose(fp);

						fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\11800000/g' /boot/config.txt", "r");
						pclose(fp);

						for (i = 1; i <= 4; i++)
							draw_square_FORMAC(i);
					}

					switch(switch_tag) {
						case 0:
							curr_menu = 0;

							fp = popen("sudo su -c \"echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor\"", "r");
							pclose(fp);

							fp = popen("sudo su -c \"echo ondemand > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor\"", "r");
							pclose(fp);

							fp = popen("sudo sed -i 's/\\(governor=\\).*/\\1ondemand/g' /boot/config.txt", "r");
							pclose(fp);

							fp = popen("sudo su -c \"echo enabled > /sys/class/thermal/thermal_zone0/mode\"", "r");
							pclose(fp);
							break;
						case 1:
							curr_menu = 1;
							highlight_menu(curr_menu);

							fp = popen("sudo su -c \"echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor\"", "r");
							pclose(fp);

							fp = popen("sudo su -c \"echo ondemand > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor\"", "r");
							pclose(fp);

							fp = popen("sudo sed -i 's/\\(governor=\\).*/\\1ondemand/g' /boot/config.txt", "r");
							pclose(fp);

							fp = popen("sudo su -c \"echo enabled > /sys/class/thermal/thermal_zone0/mode\"", "r");
							pclose(fp);
							break;
						case 2:
							curr_menu = 0;

							fp = popen("sudo su -c \"echo powersave > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor\"", "r");
							pclose(fp);

							fp = popen("sudo su -c \"echo powersave > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor\"", "r");
							pclose(fp);

							fp = popen("sudo sed -i 's/\\(governor=\\).*/\\1powersave/g' /boot/config.txt", "r");
							pclose(fp);

							fp = popen("sudo su -c \"echo enabled > /sys/class/thermal/thermal_zone0/mode\"", "r");
							pclose(fp);
							break;
						case 3:
							curr_menu = 0;

							fp = popen("sudo su -c \"echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor\"", "r");
							pclose(fp);

							fp = popen("sudo su -c \"echo performance > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor\"", "r");
							pclose(fp);

							fp = popen("sudo sed -i 's/\\(governor=\\).*/\\1performance/g' /boot/config.txt", "r");
							pclose(fp);

							fp = popen("sudo su -c \"echo disabled > /sys/class/thermal/thermal_zone0/mode\"", "r");
							pclose(fp);
							fp = popen("sudo su -c \"echo 0 > /sys/class/thermal/thermal_zone0/cdev0/cur_state\"", "r");
							pclose(fp);
							fp = popen("sudo su -c \"echo 0 > /sys/class/thermal/thermal_zone0/cdev1/cur_state\"", "r");
							pclose(fp);
							fp = popen("sudo su -c \"echo 0 > /sys/class/thermal/thermal_zone0/cdev2/cur_state\"", "r");
							pclose(fp);
							break;
					}
				}

				if (key == 'q' || key == ' ') {
					mode = 0;

					for (i = 0; i < 4; i++)
						draw_square_CPUGOVER(i, mode);
					draw_square_B(mode);
					highlight_menu(curr_menu);
				} else if (key == 'C') {	//right
					draw_square_CPUGOVER(switch_tag, mode);

					if (switch_tag < MAX_CPU_SQ - 1)
						highlight_square(++switch_tag);
					else {
						switch_tag = 0;
						highlight_square(switch_tag);
					}
				} else if (key == 'D') {	//left
					draw_square_CPUGOVER(switch_tag, mode);

					if (switch_tag > 0)
						highlight_square(--switch_tag);
					else {
						switch_tag = MAX_CPU_SQ - 1;
						highlight_square(switch_tag);
					}
				}
			} else if (mode == 2 || mode == 4) {
				if (key == ' ') {
					dirty = 1;
					switch(switch_tag) {
						case 0:
							if (mode == 2 && a53_max >= 408 ) {
								fp = popen("sudo su -c \"echo 408000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_minfreq=\\).*/\\1408000/g' /boot/config.txt", "r");
								pclose(fp);

								dirty = 0;
							} else if (mode == 4 && a53_min <= 408) {
								fp = popen("sudo su -c \"echo 408000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_maxfreq=\\).*/\\1408000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 1:
							if (mode == 2 && a53_max >= 600 ) {
								fp = popen("sudo su -c \"echo 600000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_minfreq=\\).*/\\1600000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 4 && a53_min <= 600) {
								fp = popen("sudo su -c \"echo 600000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_maxfreq=\\).*/\\1600000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 2:
							if (mode == 2 && a53_max >= 816 ) {
								fp = popen("sudo su -c \"echo 816000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_minfreq=\\).*/\\1816000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 4 && a53_min <= 816) {
								fp = popen("sudo su -c \"echo 816000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_maxfreq=\\).*/\\1816000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 3:
							if (mode == 2 && a53_max >= 1008 ) {
								fp = popen("sudo su -c \"echo 1008000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_minfreq=\\).*/\\11008000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 4 && a53_min <= 1008) {
								fp = popen("sudo su -c \"echo 1008000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_maxfreq=\\).*/\\11008000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 4:
							if (mode == 2 && a53_max >= 1200 ) {
								fp = popen("sudo su -c \"echo 1200000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_minfreq=\\).*/\\11200000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 4 && a53_min <= 1200) {
								fp = popen("sudo su -c \"echo 1200000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_maxfreq=\\).*/\\11200000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 5:
							if (mode == 2 && a53_max >= 1416 ) {
								fp = popen("sudo su -c \"echo 1416000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_minfreq=\\).*/\\11416000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 4 && a53_min <= 1416) {
								fp = popen("sudo su -c \"echo 1416000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a53_maxfreq=\\).*/\\11416000/g' /boot/config.txt", "r");
								pclose(fp);

								dirty = 0;
							}
							break;
					}
				}

				if (key == 'q' || key == ' ') {
					mode = 0;

					for (i = 0; i < MAX_A53_FREQ; i++)
						draw_square_A53FREQ(i, mode);
					highlight_menu(curr_menu);
				} else if (key == 'C') {        //right
					draw_square_A53FREQ(switch_tag, mode);

					if (switch_tag < MAX_A53_FREQ - 1)
						highlight_a53_freq(++switch_tag);
					else {
						switch_tag = 0;
						highlight_a53_freq(switch_tag);
					}
				} else if (key == 'D') {        //left
					draw_square_A53FREQ(switch_tag, mode);

					if (switch_tag > 0)
						highlight_a53_freq(--switch_tag);
					else {
						switch_tag = MAX_A53_FREQ - 1;
						highlight_a53_freq(switch_tag);
					}
				}
			}else if (mode == 3 || mode == 5) {
				if (key == ' ') {
					dirty = 1;
					switch(switch_tag) {
						case 0:
							if (mode == 3 && a72_max >= 408 ) {
								fp = popen("sudo su -c \"echo 408000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\1408000/g' /boot/config.txt", "r");
								pclose(fp);

								dirty = 0;
							} else if (mode == 5 && a72_min <= 408) {
								fp = popen("sudo su -c \"echo 408000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\1408000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 1:
							if (mode == 3 && a72_max >= 600 ) {
								fp = popen("sudo su -c \"echo 600000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\1600000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 5 && a72_min <= 600) {
								fp = popen("sudo su -c \"echo 600000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\1600000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 2:
							if (mode == 3 && a72_max >= 816 ) {
								fp = popen("sudo su -c \"echo 816000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\1816000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 5 && a72_min <= 816) {
								fp = popen("sudo su -c \"echo 816000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\1816000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 3:
							if (mode == 3 && a72_max >= 1008 ) {
								fp = popen("sudo su -c \"echo 1008000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\11008000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 5 && a72_min <= 1008) {
								fp = popen("sudo su -c \"echo 1008000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\11008000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 4:
							if (mode == 3 && a72_max >= 1200 ) {
								fp = popen("sudo su -c \"echo 1200000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\11200000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 5 && a72_min <= 1200) {
								fp = popen("sudo su -c \"echo 1200000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\11200000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 5:
							if (mode == 3 && a72_max >= 1416 ) {
								fp = popen("sudo su -c \"echo 1416000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\11416000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 5 && a72_min <= 1416) {
								fp = popen("sudo su -c \"echo 1416000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\11416000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 6:
							if (mode == 3 && a72_max >= 1608 ) {
								fp = popen("sudo su -c \"echo 1608000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\11608000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 5 && a72_min <= 1608) {
								fp = popen("sudo su -c \"echo 1608000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\11608000/g' /boot/config.txt", "r");
								pclose(fp);
							}
							break;
						case 7:
							if (mode == 3 && a72_max >= 1800 ) {
								fp = popen("sudo su -c \"echo 1800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_minfreq=\\).*/\\11800000/g' /boot/config.txt", "r");
								pclose(fp);
							} else if (mode == 5 && a72_min <= 1800) {
								fp = popen("sudo su -c \"echo 1800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq\"", "r");
								pclose(fp);

								fp = popen("sudo sed -i 's/\\(a72_maxfreq=\\).*/\\11800000/g' /boot/config.txt", "r");
								pclose(fp);

								dirty = 0;
							}
							break;
					}
				}

				if (key == 'q' || key == ' ') {
					mode = 0;

					for (i = 0; i < 9; i++)
						draw_square_A72FREQ(i, mode);
					highlight_menu(curr_menu);
				} else if (key == 'C') {	//right
					draw_square_A72FREQ(switch_tag, mode);

					if (switch_tag < MAX_A72_FREQ - 1)
						highlight_a72_freq(++switch_tag);
					else {
						switch_tag = 0;
						highlight_a72_freq(switch_tag);
					}
				} else if (key == 'D') {	//left
					draw_square_A72FREQ(switch_tag, mode);

					if (switch_tag > 0)
						highlight_a72_freq(--switch_tag);
					else {
						switch_tag = MAX_A72_FREQ - 1;
						highlight_a72_freq(switch_tag);
					}
				}
			} else if (mode == 0) {
				if (key == 'c') {
					mode = 1;

					draw_square_B(mode);

					for (i = 0; i < 4; i++)
						draw_square_CPUGOVER(i, mode);

					for (i = 1; i <= 4; i++)
						draw_square_FORMAC(i);

					highlight_square(curr_governor);

					switch_tag = curr_governor;
				} else if (curr_governor == 1) {
					if (key == 'A' || key == 'B') {	//up, down
						draw_square_FORMAC(curr_menu);

						if (curr_menu == 1)
							curr_menu = 2;
						else if (curr_menu == 2)
							curr_menu = 1;
						else if (curr_menu == 3)
							curr_menu = 4;
						else if (curr_menu == 4)
							curr_menu = 3;

						highlight_menu(curr_menu);
					} else if (key == 'C' || key == 'D') {	//left, right
						draw_square_FORMAC(curr_menu);

						if (curr_menu == 1)
							curr_menu = 3;
						else if (curr_menu == 3)
							curr_menu = 1;
						else if (curr_menu == 2)
							curr_menu = 4;
						else if (curr_menu == 4)
							curr_menu = 2;

						highlight_menu(curr_menu);
					} else if (key == ' ') {
						mode = curr_menu + 1;

						switch(curr_menu) {
							case 0:
								draw_square_B(mode);

								for (i = 0; i < 4; i++)
									draw_square_CPUGOVER(i, mode);

								highlight_square(curr_tag);
								break;
							case 1:
							case 3:
								for (i = 0; i < MAX_A53_FREQ; i++)
									draw_square_A53FREQ(i, mode);

								highlight_a53_freq(curr_tag);
								break;
							case 2:
							case 4:
								for (i = 0; i < MAX_A72_FREQ; i++)
									draw_square_A72FREQ(i, mode);

								highlight_a72_freq(curr_tag);
								break;
						}

						switch_tag = curr_tag;
					}
				}
			}
		}

		refresh();

		for (i = 0; i < 9; i++) {
			wrefresh(FORMA[i]);
			wrefresh(FORMC[i]);
		}

		for (i = 0; i < 6; i++) {
			wrefresh(FORMB[i]);
			wrefresh(FORMD[i]);
		}

		for (i = 0; i < MAX_CPU_SQ; i++)
			wrefresh(CPUGOVER[i]);

		for (i = 0; i < MAX_A53_FREQ; i++)
			wrefresh(A53FREQ[i]);

		for (i = 0; i < MAX_A72_FREQ; i++)
			wrefresh(A72FREQ[i]);

		wrefresh(BOARDA);
		wrefresh(BOARDB);
		wrefresh(BOARDC);
	}

	delwin(BOARDA);
	delwin(BOARDB);
	delwin(BOARDC);

	endwin();
	return 0;
}
