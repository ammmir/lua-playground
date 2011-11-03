co1 = coroutine.create(
  function()
    while true do
      local x = io.read()  -- read one char
      coroutine.yield(x)
    end
  end
  )

while coroutine.status(co1) ~= 'dead' do
  success, val = coroutine.resume(co1)

  if not success then
    os.exit(1)
  elseif val == nil then
    os.exit(0)
  end

  print(val)
end
