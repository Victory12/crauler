#!/usr/bin/perl -w
use strict;
use warnings;
use DDP;
use AnyEvent::HTTP;
use AnyEvent;
use v5.10;

my @urls = qw(
	http://pandok.ru/zakazat-banket
	http://pandok.ru/sezonnoe-menyu
	http://pandok.ru/sezonnoe-menyu/product/221-salat-letnij
);

my $cv = AnyEvent->condvar;
my @size_urls;
my $count = 0;
my $max = 4;
 
for (1 .. $max) {
   send_url();
}
$cv->recv;
 
 
sub send_url {
	return if $#size_urls >= 10000;
 
	my $url = $urls[$count];
	return unless defined $url;
 
	$count++;
	say "Start ($count) $url";
	$cv->begin;
	http_get $url, sub {
		my ($html) = @_;
		say "$url received, Size: ", length $html;
		push @size_urls, {url => $url, size => length $html};
		@urls = (@urls, get_data($html, $url, @urls)) if $#urls < 10000;
		$cv->end;
		send_url();
	};
	return 1;
}

sub get_data{
    my $body = shift;
    my $url = shift;
    my @urls = @_;
    my @array;
    $body =~ s[<head>(.*)</head>][]s;
    while($body =~ s[href="($url[^"]*|/[^"]*)"][]s){
       my $str = $1;
       $str =~ s[^/(.*)][http://pandok.ru/$1];      
       unless ( $str ~~ @urls )   {
       	  push @array,$str unless $str =~ /search/;
       }  
    }
    my %hash;
    @array=grep{!$hash{$_}++} @array;
    return @array;
}