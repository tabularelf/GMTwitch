function TwitchUnixTimeToDatetime(_unix, _targetTimeZone = timezone_utc) {
	var _dt = date_create_datetime(1970, 1, 1, 0, 0, _unix);
	var _timezone = date_get_timezone();
	date_set_timezone(_targetTimeZone);
	var _offset = date_hour_span(_dt, date_current_datetime());
	_dt = date_create_datetime(1970, 1, 1, _offset, 0, _unix);
	date_set_timezone(_timezone);
	return _dt;
}