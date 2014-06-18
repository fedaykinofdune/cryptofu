require 'luarocks_path'
require 'pl.app'.require_here ".."
local utest = require 'unittest'
local d = require 'pl.pretty'.dump
dump = function (t) return d (t) end

local mintpal_cookies = require 'tests.api_testkeys'.mintpal

local session = require 'exchange.mintpal' (mintpal_cookies)
assert (session)

local make_retry = require 'tools.retry'
local session = make_retry (session, 20, "timeout", "response not from MintPal!")

local tests_v2query = 
{
  test_bogusmarket = function ()
    local r, errmsg = session:markethistory ("BTC", "MRO")

    assert (not r and errmsg == "The market does not exist.")
  end,

  test_markethistory = function ()
    local r = session:markethistory ("BTC", "LTC")

    assert (next(r))
  end,

  test_orderbook = function ()
    local r = assert (session:orderbook ("BTC", "LTC"))

    assert (r.buy and r.sell)
    assert (r.sell.amount and r.buy.amount)
    assert (r.sell.price and r.buy.price)
  end,

  test_mixcasequery = function ()
    local r = assert (session:orderbook ("BtC", "caiX"))

    assert (r.buy and r.sell)
    assert (r.sell.amount and r.buy.amount)
    assert (r.sell.price and r.buy.price)
  end,
}

local tests_webquery = 
{
  test_balance = function ()
    local r = assert (session:balance ())

    dump (r)
    assert (r.AC > 0)
  end,

  test_openorders = function ()
    local r = assert (session:openorders ("BTC", "LTC"))
    dump (r)
    r = assert (session:openorders ("BTC", "AC"))
    dump (r)
    r = assert (session:openorders ("BTC", "CINnI"))
    dump (r)
  end,

  test_buy = function ()
    local r = assert (session:buy ("BTC", "CINNI", 0.000011, 10.001))

    dump (r)
  end,

  test_sell = function ()
    local r = assert (session:sell ("BTC", "AC", 0.015, 1))

    dump (r)
  end,

  test_cancelorder = function ()
    local orders = session:openorders ("BTC", "CinnI")
    for _, each in ipairs (orders) do
      dump (assert (session:cancelorder("BTC", "cinni", each.order_id)))
    end
    
    orders = session:openorders ("BTC", "AC")
    for _, each in ipairs (orders) do
      dump (assert (session:cancelorder("BTC", "AC", each.order_id)))
    end
  end,

  test_tradehistory = function ()
    local r = assert (session:tradehistory ("BTC", "LTC"))

    dump (r)
    assert (#r > 0)
  end,
}

utest.run (tests_v2query)
utest.run (tests_webquery)
-- utest.run_single (tests, "test_tradehistory")
-- utest.run_single (tests, "test_balance")
-- utest.run_single (tests, "test_sell")
