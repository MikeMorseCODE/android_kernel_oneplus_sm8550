// SPDX-License-Identifier: GPL-2.0-only
/*
 * OnePlus tri-state alert slider driver
 *
 * Uses two GPIO inputs from hall-effect sensors to detect three slider
 * positions (ring / vibrate / silent) and reports state via extcon.
 *
 * DTS binding:
 *   oplus,tri-state-key {
 *       compatible = "oplus,tri-state-key";
 *       interrupt-parent = <&tlmm>;
 *       interrupts = <42 IRQ_TYPE_EDGE_BOTH>, <43 IRQ_TYPE_EDGE_BOTH>;
 *       interrupt-names = "key-up", "key-down";
 *       gpios = <&tlmm 42 GPIO_ACTIVE_LOW>, <&tlmm 43 GPIO_ACTIVE_LOW>;
 *   };
 *
 * Position logic (active-low sensors):
 *   up=1, down=1  -> RING     (bottom of travel)
 *   up=0, down=1  -> VIBRATE  (middle)
 *   up=0, down=0  -> SILENT   (top of travel)
 */
#include <linux/extcon-provider.h>
#include <linux/gpio/consumer.h>
#include <linux/interrupt.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/workqueue.h>

enum trikey_pos {
	POS_RING    = 0,
	POS_VIBRATE = 1,
	POS_SILENT  = 2,
};

/* extcon cables: one per position; active cable = current position */
static const unsigned int trikey_cables[] = {
	EXTCON_MECHANICAL,   /* ring    */
	EXTCON_JACK_HEADSET, /* vibrate — repurposed cable ID */
	EXTCON_JACK_VIDEO_OUT, /* silent — repurposed cable ID */
	EXTCON_NONE,
};

struct trikey_dev {
	struct device      *dev;
	struct extcon_dev  *edev;
	struct gpio_desc   *gpio_up;
	struct gpio_desc   *gpio_down;
	struct delayed_work work;
	int                 irq_up;
	int                 irq_down;
	enum trikey_pos     pos;
};

static enum trikey_pos trikey_read_pos(struct trikey_dev *td)
{
	int up   = gpiod_get_value_cansleep(td->gpio_up);
	int down = gpiod_get_value_cansleep(td->gpio_down);

	if (up && down)
		return POS_RING;
	if (!up && down)
		return POS_VIBRATE;
	/* up=0 down=0, or up=1 down=0 (transient) → treat as SILENT */
	return POS_SILENT;
}

static void trikey_update(struct work_struct *work)
{
	struct trikey_dev *td =
		container_of(work, struct trikey_dev, work.work);
	enum trikey_pos new_pos = trikey_read_pos(td);

	if (new_pos == td->pos)
		return;

	/* clear old position cable */
	extcon_set_state_sync(td->edev, trikey_cables[td->pos], false);
	/* assert new position cable */
	extcon_set_state_sync(td->edev, trikey_cables[new_pos], true);

	dev_dbg(td->dev, "slider: %d -> %d\n", td->pos, new_pos);
	td->pos = new_pos;
}

static irqreturn_t trikey_irq(int irq, void *data)
{
	struct trikey_dev *td = data;

	/* debounce: wait 30 ms before sampling GPIO */
	schedule_delayed_work(&td->work, msecs_to_jiffies(30));
	return IRQ_HANDLED;
}

static int trikey_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct trikey_dev *td;
	int ret;

	td = devm_kzalloc(dev, sizeof(*td), GFP_KERNEL);
	if (!td)
		return -ENOMEM;

	td->dev = dev;

	td->gpio_up = devm_gpiod_get_index(dev, NULL, 0, GPIOD_IN);
	if (IS_ERR(td->gpio_up))
		return dev_err_probe(dev, PTR_ERR(td->gpio_up),
				     "failed to get up gpio\n");

	td->gpio_down = devm_gpiod_get_index(dev, NULL, 1, GPIOD_IN);
	if (IS_ERR(td->gpio_down))
		return dev_err_probe(dev, PTR_ERR(td->gpio_down),
				     "failed to get down gpio\n");

	td->edev = devm_extcon_dev_allocate(dev, trikey_cables);
	if (IS_ERR(td->edev))
		return PTR_ERR(td->edev);

	ret = devm_extcon_dev_register(dev, td->edev);
	if (ret)
		return dev_err_probe(dev, ret, "failed to register extcon\n");

	INIT_DELAYED_WORK(&td->work, trikey_update);

	td->irq_up   = gpiod_to_irq(td->gpio_up);
	td->irq_down = gpiod_to_irq(td->gpio_down);

	ret = devm_request_irq(dev, td->irq_up, trikey_irq,
			       IRQF_TRIGGER_RISING | IRQF_TRIGGER_FALLING,
			       "trikey-up", td);
	if (ret)
		return dev_err_probe(dev, ret, "failed to request up irq\n");

	ret = devm_request_irq(dev, td->irq_down, trikey_irq,
			       IRQF_TRIGGER_RISING | IRQF_TRIGGER_FALLING,
			       "trikey-down", td);
	if (ret)
		return dev_err_probe(dev, ret, "failed to request down irq\n");

	platform_set_drvdata(pdev, td);

	/* read initial position */
	td->pos = trikey_read_pos(td);
	extcon_set_state_sync(td->edev, trikey_cables[td->pos], true);

	dev_info(dev, "tri-state key ready, position=%d\n", td->pos);
	return 0;
}

static void trikey_remove(struct platform_device *pdev)
{
	struct trikey_dev *td = platform_get_drvdata(pdev);
	cancel_delayed_work_sync(&td->work);
}

static const struct of_device_id trikey_of_match[] = {
	{ .compatible = "oplus,tri-state-key" },
	{ }
};
MODULE_DEVICE_TABLE(of, trikey_of_match);

static struct platform_driver trikey_driver = {
	.probe  = trikey_probe,
	.remove_new = trikey_remove,
	.driver = {
		.name           = "oplus-tri-state-key",
		.of_match_table = trikey_of_match,
	},
};
module_platform_driver(trikey_driver);

MODULE_AUTHOR("OnePlus SM8550 Community");
MODULE_DESCRIPTION("OnePlus tri-state alert slider driver");
MODULE_LICENSE("GPL");
