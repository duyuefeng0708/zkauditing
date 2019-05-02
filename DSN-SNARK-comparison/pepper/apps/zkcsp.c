#include <gmp.h>
#include <stdint.h>

struct In {
  mpz_t a; //base
  mpz_t b; //exp
};
struct Out {
  mpz_t c; //result
};

int compute(struct In* input, struct Out* output){
  mpz_t a, b, c, p;
  mpz_init(a);
  mpz_init(b);
  mpz_init(c);
  mpz_init(p); //modulo

  //mpz_set_si(b, input->data[1]);
  mpz_set_str(p,
  "2102938470192837410982374019283471029837401298347120984710298347109283471029847102983741029384710293841023874601892364018236409182634098126304816203948612093461029386401928364019286340918263049182630941862039486120394861209348610293846102938461092836401928364019283460192836409132861029837410928374019283741092837410928371092837401298374019823740192837401982374019283740192837401923874102938740192837410928374109283471092387401928374109238741092384710923874102938741092387401298374019283740192837401928374019283741029387410293874102938471209384710923874019283741092837401923874102983740192387410983874019283740923874829581123948653282398625", 10);
  //mpz_add(c, a, b);
  //mpz_mul(c, a, b);
  mpz_powm(c,a,b,p);  
  //mpz_sub(c, c, c);
  //mpz_neg(c, c);
  // mpz_set(output->b, c);

  mpz_clear(a);
  mpz_clear(b);
  mpz_clear(c);
  mpz_clear(p);
}
