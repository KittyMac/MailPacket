#include "stdio.h"
#include "sasl/sasl.h"
#include "sasl/saslutil.h"

int main(int argc, char ** argv) {
    fprintf(stderr, "libsasl test\n");
    
    sasl_erasebuffer(NULL, 0);
    
    return 0;
}
