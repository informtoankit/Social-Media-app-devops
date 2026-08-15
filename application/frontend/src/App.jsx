import { useState } from 'react'

function App() {
  const [message] = useState('InstaClone — coming soon')

  return (
    <div style={{ fontFamily: 'sans-serif', textAlign: 'center', marginTop: '4rem' }}>
      <h1>{message}</h1>
      <p>Backend + Frontend running successfully via Docker 🎉</p>
    </div>
  )
}

export default App