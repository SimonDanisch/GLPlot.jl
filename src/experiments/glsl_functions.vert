vec3 rgb2hsv(vec3 rgb)
{
    vec3       hsv;
    float      minimum, maximum, delta;

    minimum = rgb.r < rgb.g ? rgb.r : rgb.g;
    minimum = minimum  < rgb.b ? minimum  : rgb.b;

    maximum = rgb.r > rgb.g ? rgb.r : rgb.g;
    maximum = maximum  > rgb.b ? maximum  : rgb.b;

    hsv.z = maximum;                                // v
    delta = maximum - minimum;
    if( maximum > 0.0 ) { // NOTE: if Max is == 0, this divide would cause a crash
        hsv.y = (delta / maximum);                  // s
    } else {
        // if maximum is 0, then r = g = b = 0              
            // s = 0, v is undefined
        hsv.y = 0.0;
        hsv.x = 0.0;                            // its now undefined
        return hsv;
    }
    if( rgb.r >= maximum )                           // > is bogus, just keeps compilor happy
        hsv.x = ( rgb.g - rgb.b ) / delta;        // between yellow & magenta
    else
    if( rgb.g >= maximum )
        hsv.x = 2.0 + ( rgb.b - rgb.r ) / delta;  // between cyan & yellow
    else
        hsv.x = 4.0 + ( rgb.r - rgb.g ) / delta;  // between magenta & cyan

    hsv.x *= 60.0;                              // degrees

    if( hsv.x < 0.0 )
        hsv.x += 360.0;

    return hsv;
}


vec3 hsv2rgb(vec3 hsv)
{
    float      hh, p, q, t, ff;
    int        i;
    vec3        rgb;

    if(hsv.y <= 0.0) {       // < is bogus, just shuts up warnings
        rgb.r = hsv.z;
        rgb.g = hsv.z;
        rgb.b = hsv.z;
        return rgb;
    }
    hh = hsv.x;
    if(hh >= 360.0) hh = 0.0;
    hh /= 60.0;
    i = (int)hh;
    ff = hh - i;
    p = hsv.z * (1.0 - hsv.y);
    q = hsv.z * (1.0 - (hsv.y * ff));
    t = hsv.z * (1.0 - (hsv.y * (1.0 - ff)));

    switch(i) {
    case 0:
        rgb.r = hsv.z;
        rgb.g = t;
        rgb.b = p;
        break;
    case 1:
        rgb.r = q;
        rgb.g = hsv.z;
        rgb.b = p;
        break;
    case 2:
        rgb.r = p;
        rgb.g = hsv.z;
        rgb.b = t;
        break;

    case 3:
        rgb.r = p;
        rgb.g = q;
        rgb.b = hsv.z;
        break;
    case 4:
        rgb.r = t;
        rgb.g = p;
        rgb.b = hsv.z;
        break;
    case 5:
    default:
        rgb.r = hsv.z;
        rgb.g = p;
        rgb.b = q;
        break;
    }
    return rgb;     
}