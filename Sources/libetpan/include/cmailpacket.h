#ifndef ctess_h
#define ctess_h

#import <stdlib.h>

typedef struct CIMAP {
    void * mailimap;
} CIMAP;

extern void * cmailimap_new();
extern int cmailimap_ssl_connect(void * f, const char * server, uint16_t port);
extern int cmailimap_login(void * session, const char * userid, const char * password);
extern int cmailimap_select(void * session, const char * mb);
extern int cmailimap_uid_search(void * session, int dt_day, int dt_month, int dt_year);

#endif
