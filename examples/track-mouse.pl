use strict;
use warnings;
use Prima qw(Application);
use PDL;
use PDL::Prima::DirectImage;

$|++;
my $image = Prima::Image->new(
	width => 800,
	height => 800,
	type => im::bpp24,
);

# Create an initial gradient in the lower left corner
$image->as_pdl
	.= 255 - rvals($image->size, {Center=>[$image->width / 4, $image->height / 4]})->dummy(0, 3);

my $w = Prima::MainWindow->create(
	size => [$image->size],
	onPaint => sub {
		my $self = shift;
		$self->begin_paint;
		$self->put_image(0, 0, $image);
		$self->end_paint;
	},
	onSize => sub {
		my ($new_x, $new_y) = @_[3,4];
		$image->size($new_x, $new_y);
	},
	onMouseMove => sub {
		my ($self, undef, $x, $y) = @_;
		print "\rMouse is at $x, $y";
		# Update the gradient to track the mouse pointer
		$image->as_pdl .= 255 - rvals($image->size, {Center => [$x, $y]})->dummy(0, 3);
		$image->data($image->data);
		$self->repaint;
	},
);

run Prima;
print "\n";