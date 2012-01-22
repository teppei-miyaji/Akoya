package KaiBashira::TimeZone;
use Mojo::Base -base;
use Data::Dumper;

our $MAPPING = {
        "International Date Line West" => "Pacific/Midway",
        "Midway Island"                => "Pacific/Midway",
        "Samoa"                        => "Pacific/Pago_Pago",
        "Hawaii"                       => "Pacific/Honolulu",
        "Alaska"                       => "America/Juneau",
        "Pacific Time (US & Canada)"   => "America/Los_Angeles",
        "Tijuana"                      => "America/Tijuana",
        "Mountain Time (US & Canada)"  => "America/Denver",
        "Arizona"                      => "America/Phoenix",
        "Chihuahua"                    => "America/Chihuahua",
        "Mazatlan"                     => "America/Mazatlan",
        "Central Time (US & Canada)"   => "America/Chicago",
        "Saskatchewan"                 => "America/Regina",
        "Guadalajara"                  => "America/Mexico_City",
        "Mexico City"                  => "America/Mexico_City",
        "Monterrey"                    => "America/Monterrey",
        "Central America"              => "America/Guatemala",
        "Eastern Time (US & Canada)"   => "America/New_York",
        "Indiana (East)"               => "America/Indiana/Indianapolis",
        "Bogota"                       => "America/Bogota",
        "Lima"                         => "America/Lima",
        "Quito"                        => "America/Lima",
        "Atlantic Time (Canada)"       => "America/Halifax",
        "Caracas"                      => "America/Caracas",
        "La Paz"                       => "America/La_Paz",
        "Santiago"                     => "America/Santiago",
        "Newfoundland"                 => "America/St_Johns",
        "Brasilia"                     => "America/Sao_Paulo",
        "Buenos Aires"                 => "America/Argentina/Buenos_Aires",
        "Georgetown"                   => "America/Argentina/San_Juan",
        "Greenland"                    => "America/Godthab",
        "Mid-Atlantic"                 => "Atlantic/South_Georgia",
        "Azores"                       => "Atlantic/Azores",
        "Cape Verde Is."               => "Atlantic/Cape_Verde",
        "Dublin"                       => "Europe/Dublin",
        "Edinburgh"                    => "Europe/Dublin",
        "Lisbon"                       => "Europe/Lisbon",
        "London"                       => "Europe/London",
        "Casablanca"                   => "Africa/Casablanca",
        "Monrovia"                     => "Africa/Monrovia",
        "UTC"                          => "Etc/UTC",
        "Belgrade"                     => "Europe/Belgrade",
        "Bratislava"                   => "Europe/Bratislava",
        "Budapest"                     => "Europe/Budapest",
        "Ljubljana"                    => "Europe/Ljubljana",
        "Prague"                       => "Europe/Prague",
        "Sarajevo"                     => "Europe/Sarajevo",
        "Skopje"                       => "Europe/Skopje",
        "Warsaw"                       => "Europe/Warsaw",
        "Zagreb"                       => "Europe/Zagreb",
        "Brussels"                     => "Europe/Brussels",
        "Copenhagen"                   => "Europe/Copenhagen",
        "Madrid"                       => "Europe/Madrid",
        "Paris"                        => "Europe/Paris",
        "Amsterdam"                    => "Europe/Amsterdam",
        "Berlin"                       => "Europe/Berlin",
        "Bern"                         => "Europe/Berlin",
        "Rome"                         => "Europe/Rome",
        "Stockholm"                    => "Europe/Stockholm",
        "Vienna"                       => "Europe/Vienna",
        "West Central Africa"          => "Africa/Algiers",
        "Bucharest"                    => "Europe/Bucharest",
        "Cairo"                        => "Africa/Cairo",
        "Helsinki"                     => "Europe/Helsinki",
        "Kyev"                         => "Europe/Kiev",
        "Riga"                         => "Europe/Riga",
        "Sofia"                        => "Europe/Sofia",
        "Tallinn"                      => "Europe/Tallinn",
        "Vilnius"                      => "Europe/Vilnius",
        "Athens"                       => "Europe/Athens",
        "Istanbul"                     => "Europe/Istanbul",
        "Minsk"                        => "Europe/Minsk",
        "Jerusalem"                    => "Asia/Jerusalem",
        "Harare"                       => "Africa/Harare",
        "Pretoria"                     => "Africa/Johannesburg",
        "Moscow"                       => "Europe/Moscow",
        "St. Petersburg"               => "Europe/Moscow",
        "Volgograd"                    => "Europe/Moscow",
        "Kuwait"                       => "Asia/Kuwait",
        "Riyadh"                       => "Asia/Riyadh",
        "Nairobi"                      => "Africa/Nairobi",
        "Baghdad"                      => "Asia/Baghdad",
        "Tehran"                       => "Asia/Tehran",
        "Abu Dhabi"                    => "Asia/Muscat",
        "Muscat"                       => "Asia/Muscat",
        "Baku"                         => "Asia/Baku",
        "Tbilisi"                      => "Asia/Tbilisi",
        "Yerevan"                      => "Asia/Yerevan",
        "Kabul"                        => "Asia/Kabul",
        "Ekaterinburg"                 => "Asia/Yekaterinburg",
        "Islamabad"                    => "Asia/Karachi",
        "Karachi"                      => "Asia/Karachi",
        "Tashkent"                     => "Asia/Tashkent",
        "Chennai"                      => "Asia/Kolkata",
        "Kolkata"                      => "Asia/Kolkata",
        "Mumbai"                       => "Asia/Kolkata",
        "New Delhi"                    => "Asia/Kolkata",
        "Kathmandu"                    => "Asia/Katmandu",
        "Astana"                       => "Asia/Dhaka",
        "Dhaka"                        => "Asia/Dhaka",
        "Sri Jayawardenepura"          => "Asia/Colombo",
        "Almaty"                       => "Asia/Almaty",
        "Novosibirsk"                  => "Asia/Novosibirsk",
        "Rangoon"                      => "Asia/Rangoon",
        "Bangkok"                      => "Asia/Bangkok",
        "Hanoi"                        => "Asia/Bangkok",
        "Jakarta"                      => "Asia/Jakarta",
        "Krasnoyarsk"                  => "Asia/Krasnoyarsk",
        "Beijing"                      => "Asia/Shanghai",
        "Chongqing"                    => "Asia/Chongqing",
        "Hong Kong"                    => "Asia/Hong_Kong",
        "Urumqi"                       => "Asia/Urumqi",
        "Kuala Lumpur"                 => "Asia/Kuala_Lumpur",
        "Singapore"                    => "Asia/Singapore",
        "Taipei"                       => "Asia/Taipei",
        "Perth"                        => "Australia/Perth",
        "Irkutsk"                      => "Asia/Irkutsk",
        "Ulaan Bataar"                 => "Asia/Ulaanbaatar",
        "Seoul"                        => "Asia/Seoul",
        "Osaka"                        => "Asia/Tokyo",
        "Sapporo"                      => "Asia/Tokyo",
        "Tokyo"                        => "Asia/Tokyo",
        "Yakutsk"                      => "Asia/Yakutsk",
        "Darwin"                       => "Australia/Darwin",
        "Adelaide"                     => "Australia/Adelaide",
        "Canberra"                     => "Australia/Melbourne",
        "Melbourne"                    => "Australia/Melbourne",
        "Sydney"                       => "Australia/Sydney",
        "Brisbane"                     => "Australia/Brisbane",
        "Hobart"                       => "Australia/Hobart",
        "Vladivostok"                  => "Asia/Vladivostok",
        "Guam"                         => "Pacific/Guam",
        "Port Moresby"                 => "Pacific/Port_Moresby",
        "Magadan"                      => "Asia/Magadan",
        "Solomon Is."                  => "Asia/Magadan",
        "New Caledonia"                => "Pacific/Noumea",
        "Fiji"                         => "Pacific/Fiji",
        "Kamchatka"                    => "Asia/Kamchatka",
        "Marshall Is."                 => "Pacific/Majuro",
        "Auckland"                     => "Pacific/Auckland",
        "Wellington"                   => "Pacific/Auckland",
        "Nuku'alofa"                   => "Pacific/Tongatapu"
      };

our @zones;
our $zones_map = {};

has [qw/name tzinfo current_period offset/];

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = $class->SUPER::new(@_);
  $self->{name} ||= "";
  $self->{utc_offset} ||= undef;
  $self->{tzinfo} ||= $self->find_tzinfo( $self->name );
  $self->{current_period} = undef;
  $self;
}

sub utc_offset {
  my ( $self ) = @_;
  if( $self->{utc_offset} ){
    $self->{utc_offset};
  }
  else {
    #$self->{current_period} ||= $self->tzinfo->{current_period};
    #$self->{current_period}->{utc_offset};
  }
}

sub formatted_offset {
  my ( $self, $colon, $alternate_utc_string ) = @_;
  $colon ||= 1;
  #$alternate_utc_string = undef;

  my $p = "+";
  if( $self->utc_offset < 0 ){
    $p = "-";
    $self->utc_offset( $self->utc_offset * -1 );
  }

  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime( $self->utc_offset );
  
  sprintf( "%s%02d:%02d" , $p , $hour , $min );
}

sub to_s {
  my ( $self ) = @_;
  my $formatted_offset = $self->formatted_offset;
  my $name = $self->name;
  "(GMT${formatted_offset}) ${name}";
}

sub find_tzinfo {
  my ( $self, $name ) = @_;
#      require 'tzinfo' unless defined?(TZInfo)
#      ::TZInfo::Timezone.get(MAPPING[name] || name)
#    rescue TZInfo::InvalidTimezoneIdentifier
#      nil
}

sub create { &new(@_) }

sub all {
  unless( @zones ){
    my $zones_map = &zones_map;
    foreach my $key( %{ $zones_map } ){
      push @zones , $zones_map->{ $key };
    }
    @zones = sort { $a->{utc_offset} <=> $b->{utc_offset} } grep { defined } @zones;
  }
  @zones;
}

sub zones_map {
  $zones_map = {};
  foreach my $item(
           [-39_600, "International Date Line West", "Midway Island", "Samoa" ],
           [-36_000, "Hawaii" ],
           [-32_400, "Alaska" ],
           [-28_800, "Pacific Time (US & Canada)", "Tijuana" ],
           [-25_200, "Mountain Time (US & Canada)", "Chihuahua", "Mazatlan",
                     "Arizona" ],
           [-21_600, "Central Time (US & Canada)", "Saskatchewan", "Guadalajara",
                     "Mexico City", "Monterrey", "Central America" ],
           [-18_000, "Eastern Time (US & Canada)", "Indiana (East)", "Bogota",
                     "Lima", "Quito" ],
           [-16_200, "Caracas" ],
           [-14_400, "Atlantic Time (Canada)", "La Paz", "Santiago" ],
           [-12_600, "Newfoundland" ],
           [-10_800, "Brasilia", "Buenos Aires", "Georgetown", "Greenland" ],
           [ -7_200, "Mid-Atlantic" ],
           [ -3_600, "Azores", "Cape Verde Is." ],
           [      0, "Dublin", "Edinburgh", "Lisbon", "London", "Casablanca",
                     "Monrovia", "UTC" ],
           [  3_600, "Belgrade", "Bratislava", "Budapest", "Ljubljana", "Prague",
                     "Sarajevo", "Skopje", "Warsaw", "Zagreb", "Brussels",
                     "Copenhagen", "Madrid", "Paris", "Amsterdam", "Berlin",
                     "Bern", "Rome", "Stockholm", "Vienna",
                     "West Central Africa" ],
           [  7_200, "Bucharest", "Cairo", "Helsinki", "Kyev", "Riga", "Sofia",
                     "Tallinn", "Vilnius", "Athens", "Istanbul", "Minsk",
                     "Jerusalem", "Harare", "Pretoria" ],
           [ 10_800, "Moscow", "St. Petersburg", "Volgograd", "Kuwait", "Riyadh",
                     "Nairobi", "Baghdad" ],
           [ 12_600, "Tehran" ],
           [ 14_400, "Abu Dhabi", "Muscat", "Baku", "Tbilisi", "Yerevan" ],
           [ 16_200, "Kabul" ],
           [ 18_000, "Ekaterinburg", "Islamabad", "Karachi", "Tashkent" ],
           [ 19_800, "Chennai", "Kolkata", "Mumbai", "New Delhi", "Sri Jayawardenepura" ],
           [ 20_700, "Kathmandu" ],
           [ 21_600, "Astana", "Dhaka", "Almaty",
                     "Novosibirsk" ],
           [ 23_400, "Rangoon" ],
           [ 25_200, "Bangkok", "Hanoi", "Jakarta", "Krasnoyarsk" ],
           [ 28_800, "Beijing", "Chongqing", "Hong Kong", "Urumqi",
                     "Kuala Lumpur", "Singapore", "Taipei", "Perth", "Irkutsk",
                     "Ulaan Bataar" ],
           [ 32_400, "Seoul", "Osaka", "Sapporo", "Tokyo", "Yakutsk" ],
           [ 34_200, "Darwin", "Adelaide" ],
           [ 36_000, "Canberra", "Melbourne", "Sydney", "Brisbane", "Hobart",
                     "Vladivostok", "Guam", "Port Moresby" ],
           [ 39_600, "Magadan", "Solomon Is.", "New Caledonia" ],
           [ 43_200, "Fiji", "Kamchatka", "Marshall Is.", "Auckland",
                     "Wellington" ],
           [ 46_800, "Nuku'alofa" ] ){
    my ( $offset , @places ) = @{ $item };
    foreach my $place( @places ){
      $zones_map->{ $place } = __PACKAGE__->new( name => $place , utc_offset => $offset );
    }
  }
  $zones_map;
}

1;