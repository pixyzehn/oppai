use strict;
use warnings;
use URI;
use HTTP::Request;
use LWP::UserAgent;
use JSON;
use Digest::MD5 qw/md5_hex/;
use Path::Class qw/dir/;
use Encode;
use utf8;

my $user_id = '';
my $app_id = 'JKLkvrOvO6JkR0DncCjeyNS+vT2PgWmRyxzbEm3D+6o';

my $ua = LWP::UserAgent->new;
my $dir = dir('./data');
my $page_count = 0;
my $download_count = 0;

while (1) {
    my $offset = $page_count * 50;
    my $uri = URI->new('https://api.datamarket.azure.com/Bing/Search/Image');
    $uri->query_form(
        Query => "'oppai'",
        Market => "'ja-JP'",
        Adult => "'off'",
        '$format' => "JSON",
        '$top' => 50,
        '$skip' => $offset,
    );
    my $req = HTTP::Request->new( 'GET' => $uri );
    $req->authorization_basic( $user_id, $app_id );
    my $res = $ua->request($req);
    die $res->status_line if $res->is_error;
    my $json_text = $res->content;
    my $ref = decode_json($json_text);
    last unless @{ $ref->{d}{results} };

    for my $result ( @{ $ref->{d}{results} } ) {
        next unless $result->{MediaUrl} =~ /\.jpg$/i;
        $download_count++;
        my $filename = md5_hex( encode_utf8( $result->{MediaUrl} )) . '.jpg';
        my $filepath = $dir->file($filename);
        next if -f $filepath;
        print encode_utf8("$download_count : Download... $result->{MediaUrl}\n");
        $res = $ua->get( $result->{MediaUrl}, ':content_file' => $filepath->stringify);
    }
    $page_count++;
}

