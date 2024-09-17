function __TwitchUUIDv4() {
    //As per https://www.cryptosys.net/pki/uuid-rfc4122.html (though without the hyphens)
    var _UUID = md5_string_unicode(string(date_current_datetime()) + string((get_timer() << 1000000)));
    _UUID = string_set_byte_at(_UUID, 13, ord("4"));
    _UUID = string_set_byte_at(_UUID, 17, ord(choose("8", "9", "a", "b")));
    
    return _UUID;
}
