#include "stdio.h"
#include "stdlib.h"
#include <string.h>

#include "mailimap.h"

void * cmailimap_new() {
    return mailimap_new(0, NULL);
}

int cmailimap_ssl_connect(void * f, const char * server, uint16_t port) {
    return mailimap_ssl_connect(f, server, port);
}

int cmailimap_login(void * session, const char * userid, const char * password) {
    return mailimap_login(session, userid, password);
}
