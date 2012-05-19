package Slic3r::Notifier;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(notify);

use FindBin;

my $notification_function;

sub notification_function {
    return $notification_function if (defined $notification_function);
    $notification_function = sub {};
    if (eval "use Growl::GNTP; 1") {
        # register growl notifications
        my $growler;
        eval {
            my $growler = Growl::GNTP->new(AppName => 'Slic3r', AppIcon => "$FindBin::Bin/var/Slic3r.png");
            $growler->register([{Name => 'SKEIN_DONE', DisplayName => 'Slicing Done'}]);
            $notification_function = sub {
                my ($summary, $message) = @_;
                $growler->notify(Event => 'SKEIN_DONE', Title => 'Slicing Done!', Message => $message);
            };
        };
    } elsif (eval "use Net::DBus; 1") {
        eval {
            my $session = Net::DBus->session;
            my $serv = $session->get_service('org.freedesktop.Notifications');
            my $notifier =
              $serv->get_object('/org/freedesktop/Notifications',
                                'org.freedesktop.Notifications');
            $notification_function = sub {
                my ($summary, $message) = @_;
                $notifier->Notify('Slic3r', 0, "$FindBin::Bin/var/Slic3r.png",
                                  $summary, $message, [], {}, -1);
            };
        };
    }
}

sub notify {
    my $summary = shift || 'Slicing Done!';
    my $message = shift || '';
    eval {
        print STDERR "Notification: @_\n";
        notification_function->($summary, $message);
    };
}

1;
